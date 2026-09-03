import pandas as pd
import geopandas as gpd
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches


# Map of the local business tax (Gewerbesteuer) treatments at the KREIS (district)
# level, built from the screened change subsample used in the research design
# (the two markdown files 2024/2025_lbt_change_check.md).
#
# A Kreis is "treated" in a year if at least one of its municipalities appears in
# that year's change file. Each Kreis is then classified by how often and in which
# direction it was treated across the two tax years 2024 and 2025:
#
#   1 hike   (orange)      treated in ONE year, that year a rate hike
#   1 cut    (light green) treated in ONE year, that year a rate cut
#   2 hikes  (red)         treated in BOTH years, both times a hike
#   2 cuts   (dark green)  treated in BOTH years, both times a cut
#   mixed    (purple)      treated in BOTH years, once up and once down
#                          (not part of the requested 4-way scheme, but 4 such
#                           Kreise exist in the data, so they get their own class
#                           rather than being silently mislabelled)
#
# Within a single Kreis-year the direction is taken as the dominant one, i.e. a
# hike if the number of municipal hikes is >= the number of cuts (cuts are rare,
# so this only matters for a handful of Kreis-years).

# Paths
md_2024 = r"C:\Users\paulm\Desktop\Masterarbeit\Claude\gptcodexlbt\2024_lbt_change_check.md"
md_2025 = r"C:\Users\paulm\Desktop\Masterarbeit\Claude\gptcodexlbt\2025_lbt_change_check.md"

kreise_shp = r"C:\Users\paulm\Desktop\Masterarbeit\Visualisierung Hebesatz\VG250_KRS_2025.shp"
laender_shp = r"C:\Users\paulm\Desktop\Masterarbeit\Visualisierung Hebesatz\VG250_LAN_2025.shp"


# --- Read the two change files and derive the 5-digit Kreis key --------------
def load_changes(path, year):
    d = pd.read_csv(path, skipinitialspace=True)
    d["kreis5"] = d["plz_kgs"].astype(str).str.zfill(8).str[:5]
    d["year"] = year
    return d[["kreis5", "year", "lbt_change"]]


changes = pd.concat(
    [load_changes(md_2024, 2024), load_changes(md_2025, 2025)],
    ignore_index=True
)

# Dominant direction per Kreis-year (hike if #hikes >= #cuts, else cut)
def dominant(sub):
    return "hike" if (sub["lbt_change"] > 0).sum() >= (sub["lbt_change"] < 0).sum() else "cut"


ky = (
    changes.groupby(["kreis5", "year"], group_keys=False)
    .apply(dominant, include_groups=False)
    .reset_index(name="dir")
)


# --- Classify each Kreis into one of the five categories ---------------------
def classify(sub):
    dirs = sorted(sub["dir"].tolist())          # e.g. ["cut"], ["hike","hike"]
    n = len(dirs)                               # number of treated years (1 or 2)
    if n == 2 and dirs == ["hike", "hike"]:
        return "two_hikes"
    if n == 2 and dirs == ["cut", "cut"]:
        return "two_cuts"
    if n == 2:
        return "mixed"                          # one hike, one cut
    if dirs == ["hike"]:
        return "one_hike"
    return "one_cut"


kreis_cat = (
    ky.groupby("kreis5", group_keys=False)
    .apply(classify, include_groups=False)
    .reset_index(name="category")
)


# --- Load Kreis boundaries (land only, GF==4) and merge ----------------------
SIMPLIFY_M = 200  # geometry simplification tolerance in metres (CRS is metric)

kreise = gpd.read_file(kreise_shp)
kreise = kreise[kreise["GF"] == 4].copy()
kreise["AGS"] = kreise["AGS"].astype(str).str.zfill(5)
kreise["geometry"] = kreise.geometry.simplify(SIMPLIFY_M, preserve_topology=True)

krs = kreise.merge(kreis_cat, left_on="AGS", right_on="kreis5", how="left")

# State boundaries (land only)
states = gpd.read_file(laender_shp)
states = states[states["GF"] == 4].copy()
states["geometry"] = states.geometry.simplify(SIMPLIFY_M, preserve_topology=True)


# --- Colors ------------------------------------------------------------------
colors = {
    "one_hike": "#f4a13c",    # orange   -> one hike
    "one_cut": "#a6d96a",     # light green -> one cut
    "two_hikes": "#d7191c",   # red      -> two hikes
    "two_cuts": "#1a7837",    # dark green -> two cuts
    "mixed": "#7b3294",       # purple   -> treated twice, once up once down
}

labels = {
    "one_hike": "Hike (1 year)",
    "one_cut": "Cut (1 year)",
    "two_hikes": "Hikes (both years)",
    "two_cuts": "Cuts (both years)",
    "mixed": "Hike & cut (both years)",
}

UNTREATED = "#e0e0e0"  # Kreise not in the subsample -> light gray background


# --- Plot --------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(8.8, 13))

# Untreated Kreise (no value after the merge) -> light gray
krs[krs["category"].isna()].plot(ax=ax, color=UNTREATED, linewidth=0)

# Treated classes, drawn from least to most emphatic so overlaps favour the
# stronger categories (matters only at shared borders, drawn thin below anyway)
for k in ["one_cut", "one_hike", "mixed", "two_cuts", "two_hikes"]:
    krs[krs["category"] == k].plot(ax=ax, color=colors[k], linewidth=0)

# Kreis borders (thin) and state borders (bold) for orientation
krs.boundary.plot(ax=ax, color="white", linewidth=0.25)
states.boundary.plot(ax=ax, color="black", linewidth=0.6)

ax.set_axis_off()

# Legend
order = ["one_hike", "two_hikes", "one_cut", "two_cuts", "mixed"]
patches = [mpatches.Patch(color=colors[k], label=labels[k]) for k in order]
patches.append(
    mpatches.Patch(facecolor=UNTREATED, edgecolor="#bdbdbd", label="Not treated")
)

# Fixed canvas so the image matches the Gemeinde map's dimensions
fig.subplots_adjust(left=0.02, right=0.98, top=0.98, bottom=0.10)

fig.legend(
    handles=patches,
    loc="lower center",
    bbox_to_anchor=(0.5, 0.01),
    ncol=3,
    frameon=True,
    fontsize=15,
    handlelength=1.2,
    columnspacing=1.0,
    handletextpad=0.5,
)

plt.savefig(
    r"C:\Users\paulm\Desktop\Masterarbeit\Visualisierung Hebesatz\Gewerbesteuer_Hebesatz_Kreis_Treatment.png",
    dpi=130,
)
plt.savefig(
    r"C:\Users\paulm\Desktop\Masterarbeit\Visualisierung Hebesatz\Gewerbesteuer_Hebesatz_Kreis_Treatment.pdf",
)

# Console summary
print("Kreis treatment categories:")
print(kreis_cat["category"].value_counts().to_string())
print("Total treated Kreise:", len(kreis_cat))

plt.show()
