import pandas as pd
import geopandas as gpd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches


# Map of the local business tax (Gewerbesteuer) rate CHANGE between two years.
# Default: change 2023 -> 2025, i.e. which municipalities changed their rate
# in 2024 and/or 2025.
# Data source: hebesaetze_gemeinden_2003_2025_wide.csv (from combine_hebesaetze.py).

# Paths
wide_csv = "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\hebesaetze_gemeinden_2003_2025_wide.csv"

gemeinden_shp = "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\VG250_GEM_2025.shp"
laender_shp = "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\VG250_LAN_2025.shp"

# Comparison years (adjust here)
YEAR_FROM = 2023   # base
YEAR_TO = 2025     # target

# Read the rate table
df = pd.read_csv(wide_csv, dtype={"ags8": str})
df["ags8"] = df["ags8"].str.zfill(8)

col_from = str(YEAR_FROM)
col_to = str(YEAR_TO)

df[col_from] = pd.to_numeric(df[col_from], errors="coerce")
df[col_to] = pd.to_numeric(df[col_to], errors="coerce")

# Net change over the period
df["delta"] = df[col_to] - df[col_from]

df = df[["ags8", "name", col_from, col_to, "delta"]]

# Build the classes (diverging: decreased / unchanged / increased).
# Changes are almost exclusively increases, so the increase arm is graded by
# size while the decrease arm stays a single class.
def classify(d):
    if pd.isna(d):
        return np.nan
    if d < 0:
        return "decreased"
    if d == 0:
        return "unchanged"
    if d <= 10:
        return "up_1_10"
    if d <= 25:
        return "up_11_25"
    if d <= 50:
        return "up_26_50"
    return "up_50plus"

df["category"] = df["delta"].apply(classify)

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

muni = municipalities.merge(df, left_on="AGS", right_on="ags8", how="left")
muni["geometry"] = muni.geometry.simplify(SIMPLIFY_M, preserve_topology=True)

# Load state boundaries (land only, GF==4 -> no maritime borders)
states = gpd.read_file(laender_shp)
states = states[states["GF"] == 4].copy()
states["geometry"] = states.geometry.simplify(SIMPLIFY_M, preserve_topology=True)

# Colors (diverging: blue = decreased, gray = unchanged, red sequence = increase by size)
colors = {
    "decreased": "#2a78d6",   # blue (decrease)
    "unchanged": "#e6e6e3",   # neutral gray
    "up_1_10": "#fcbba1",     # red sequence, light -> dark
    "up_11_25": "#fc9272",
    "up_26_50": "#ef3b2c",
    "up_50plus": "#a50f15",
}

# Short labels so all boxes fit on a single legend row (the title carries the
# "rate change" context, so the numeric classes read as increases).
labels = {
    "decreased": "decr.",
    "unchanged": "unch.",
    "up_1_10": "+1–10",
    "up_11_25": "+11–25",
    "up_26_50": "+26–50",
    "up_50plus": ">+50",
}

# Plot
# Figure width matched to Germany's bounding-box aspect (~0.74 w/h) so the map
# fills the canvas with minimal empty margins on the left/right (no stretching).
fig, ax = plt.subplots(figsize=(8.8, 13))

# Municipalities without a comparable value (unincorporated areas or a missing
# base/target year) -> white
muni[muni["category"].isna()].plot(
    ax=ax,
    color="white",
    linewidth=0
)

# Draw the classes (no municipality borders)
for k in ["unchanged", "up_1_10", "up_11_25", "up_26_50", "up_50plus", "decreased"]:
    muni[muni["category"] == k].plot(
        ax=ax,
        color=colors[k],
        linewidth=0
    )

# State boundaries
states.boundary.plot(
    ax=ax,
    color="black",
    linewidth=0.6
)

# Legend
order = ["decreased", "unchanged", "up_1_10", "up_11_25", "up_26_50", "up_50plus"]

patches = [mpatches.Patch(color=colors[k], label=labels[k]) for k in order]

patches.append(
    mpatches.Patch(
        facecolor="white",
        edgecolor="#bdbdbd",
        label="n.a."
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
    "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\Gewerbesteuer_Hebesatz_Aenderung_%d_%d.png" % (YEAR_FROM, YEAR_TO),
    dpi=130
)

plt.savefig(
    "C:\\Users\\paulm\\Desktop\\Masterarbeit\\Visualisierung Hebesatz\\Gewerbesteuer_Hebesatz_Aenderung_%d_%d.pdf" % (YEAR_FROM, YEAR_TO)
)

plt.show()
