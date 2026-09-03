import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches


# Paths
excel_file = "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\71231-01-03-5.xlsx"

gemeinden_shp = "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\VG250_GEM_2025.shp"
laender_shp = "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\VG250_LAN_2025.shp"


# Read the Excel file
df = pd.read_excel(
    excel_file,
    header=0,
    dtype={"Jahr\nGemeinden": str}
)

# Keep only the needed columns
df = df[[
    "Jahr\nGemeinden",
    "Unnamed: 1",
    "Gewerbesteuer Hebesatz"
]]

df.columns = [
    "AGS",
    "name",
    "rate"
]

# A municipality AGS is 8 digits (state + region + district + municipality).
# But independent cities (e.g. Kiel, Koeln, Muenchen) and the city-states
# Berlin/Hamburg/Bremen only carry the shorter state code (2 digits) or
# district code (5 digits) here, because they are their own district - a
# separate 8-digit entry does not exist. So pad on the RIGHT (not left) with
# zeros to 8 digits: in the AGS scheme the last 3 digits are the municipality
# number, which is always "000" for independent cities. District averages
# (Landkreise) also end up on an 8-digit code, but one that never matches a
# real municipality, so they drop out silently on the merge.
df["AGS"] = df["AGS"].str.ljust(8, "0")

# Clean the rate
df["rate"] = pd.to_numeric(df["rate"], errors="coerce")
df = df[df["rate"].notna()]
df = df[df["AGS"].str.len() == 8]

# Build the classes
bins = [0, 300, 350, 400, 450, 500, 1000]

labels = [
    "<300",
    "300–349",
    "350–399",
    "400–449",
    "450–499",
    "≥500"
]

# right=False: left-closed intervals, so that a rate of exactly 500 really
# falls into ">=500" (with right=True it would fall into "450-499").
df["category"] = pd.cut(
    df["rate"],
    bins=bins,
    labels=labels,
    right=False
)

# Geometry simplification tolerance (map units = metres, CRS is EPSG:3857).
# Reduces the number of vertices to keep the PNG/PDF small and responsive.
# At national scale ~200 m is not visible; raise for smaller files, lower for
# more detail.
SIMPLIFY_M = 200

# Load municipality boundaries and merge.
# VG250 stores each area with a Geofaktor (GF): GF==4 is actual land, while
# GF==1/2 are the coastal water bodies (North Sea / Baltic). Keeping only GF==4
# removes the maritime boundaries in the north that otherwise obscure the
# islands. Every coastal municipality still keeps its land polygon.
municipalities = gpd.read_file(gemeinden_shp)
municipalities = municipalities[municipalities["GF"] == 4].copy()
municipalities["AGS"] = municipalities["AGS"].astype(str).str.zfill(8)

muni = municipalities.merge(df, on="AGS", how="left")
muni["geometry"] = muni.geometry.simplify(SIMPLIFY_M, preserve_topology=True)

# Load state boundaries (land only, GF==4 -> no maritime borders)
states = gpd.read_file(laender_shp)
states = states[states["GF"] == 4].copy()
states["geometry"] = states.geometry.simplify(SIMPLIFY_M, preserve_topology=True)

# Colors: sequential "plasma" palette (reversed) mirroring the Destatis map
# style -> pale yellow for the lowest class through orange/red/magenta/purple
# to dark navy for the highest class. Sampled evenly across the 6 classes.
cmap = plt.get_cmap("plasma_r")
colors = {
    label: cmap(i / (len(labels) - 1))
    for i, label in enumerate(labels)
}

# Plot
# Figure width matched to Germany's bounding-box aspect (~0.74 w/h) so the map
# fills the canvas with minimal empty margins on the left/right (no stretching).
fig, ax = plt.subplots(figsize=(8.8, 13))

# Unincorporated areas (no municipality, hence no local business tax) -> light
# gray, matching the "gemeindefreies Gebiet" class in the Destatis map.
muni[muni["category"].isna()].plot(
    ax=ax,
    color="#e0e0e0",
    linewidth=0
)

# Draw the classes (no municipality borders, linewidth=0)
for k, c in colors.items():
    muni[muni["category"] == k].plot(
        ax=ax,
        color=c,
        linewidth=0
    )

# State boundaries
states.boundary.plot(
    ax=ax,
    color="black",
    linewidth=0.6
)

# Legend
patches = [mpatches.Patch(color=c, label=k) for k, c in colors.items()]

patches.append(
    mpatches.Patch(
        facecolor="#e0e0e0",
        edgecolor="#bdbdbd",
        label="No LBT"
    )
)

ax.set_axis_off()

# Fixed canvas: reserve identical margins in both scripts (no tight_layout /
# bbox_inches="tight"), so the saved image is always figsize*dpi = 2000x2600 px
# and both maps come out at exactly the same dimensions.
fig.subplots_adjust(left=0.02, right=0.98, top=0.98, bottom=0.10)

# Legend anchored to the figure (bottom centre), two rows (ncol=4).
fig.legend(
    handles=patches,
    loc="lower center",
    bbox_to_anchor=(0.5, 0.01),
    ncol=4,              # 7 boxes over two rows
    frameon=True,
    fontsize=16,
    handlelength=1.2,
    columnspacing=1.0,
    handletextpad=0.5
)

plt.savefig(
    "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\Gewerbesteuer_Hebesatz_2024.png",
    dpi=130
)

plt.savefig(
    "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\Gewerbesteuer_Hebesatz_2024.pdf"
)

plt.show()
