"""
Kombiniert die Gewerbesteuer-Hebesätze aus drei Quellen zu einem langen Panel:

  1. muni_data_hebesaetze_2003_2023.dta       -> Jahre 2003-2023 (Spalte busitaxm)
  2. 71231-01-03-5.xlsx                        -> Jahr 2024
  3. 71231-02-01-5.csv (Stichtag 30.06.2025)   -> Jahr 2025

Jahr 2025:
Die CSV enthält ABSOLUTE Hebesätze, aber nur für Gemeinden mit gemeldetem Wert.
Fehlt der Gewerbesteuer-Wert ("-"), wird der 2024er Hebesatz unverändert
fortgeschrieben. (Baden-Württemberg meldet alle Gemeinden, auch unveränderte -
unschädlich, da diese dem 2024er Stand entsprechen.)

Aggregat-Ebenen:
Die 2024er Excel enthält neben Gemeinden auch aggregierte Zeilen
(Deutschland "DG", Länder, Regierungsbezirke, Kreise). Diese werden NICHT
verworfen, sondern über die Spalte 'level' gekennzeichnet. Für eine reine
Gemeinde-Analyse einfach level == "gemeinde" filtern.

Ausgabe:
  kombiniertes_panel_hebesaetze_2003_2025.csv   (alles, mit 'level'-Spalte)
  hebesaetze_gemeinden_2003_2025_wide.csv        (nur Gemeinden, breit: ein Jahr je Spalte)
"""

import pandas as pd
import numpy as np
import geopandas as gpd

BASE  = r"C:\Users\paulm\Desktop\Masterarbeit\Visualisierung Hebesatz"
DTA   = BASE + r"\muni_data_hebesaetze_2003_2023.dta"
XL24  = BASE + r"\71231-01-03-5.xlsx"
CSV25 = BASE + r"\71231-02-01-5.csv"
SHP   = BASE + r"\VG250_GEM_2025.shp"
OUT_LONG = BASE + r"\kombiniertes_panel_hebesaetze_2003_2025.csv"
OUT_WIDE = BASE + r"\hebesaetze_gemeinden_2003_2025_wide.csv"


########################################################################
# Autoritative Gemeindeliste (nur zur Ebenen-Klassifikation der Excel)
########################################################################

muni_set = set(gpd.read_file(SHP)["AGS"].astype(str).str.zfill(8))


def classify_level(raw: str, pad: str) -> str:
    """Ebene aus dem ROHEN Amtlichen Gemeindeschlüssel bestimmen."""
    if not raw.isdigit():
        return "bund"                     # "DG" = Deutschland
    # Echte Gemeinde? (fängt auch Stadtstaaten Berlin/Hamburg ab, deren
    # 2-stelliger Rohcode auf eine 8-stellige Gemeinde-Kennung führt)
    if pad in muni_set:
        return "gemeinde"
    n = len(raw)
    if n <= 2:
        return "land"
    if n == 3:
        return "regbez"
    if n == 5:
        return "kreis"
    return "gemeinde"                     # 8-stellig, aber nicht im Shapefile


########################################################################
# 1) Panel 2003-2023 aus der .dta  (reine Gemeinde-Ebene)
########################################################################

dta = pd.read_stata(DTA)
dta["ags8"] = dta["ags"].astype("Int64").astype(str).str.zfill(8)
dta["year"] = dta["year"].astype("Int64")
dta = dta.rename(columns={"busitaxm": "hebesatz"})
dta["level"] = "gemeinde"
dta["hebesatz_source"] = "panel_2003_2023"


########################################################################
# 2) Jahr 2024 aus der Excel  (Gemeinden + Aggregate)
########################################################################

df24 = pd.read_excel(XL24, header=0, dtype={"Jahr\nGemeinden": str})
df24 = df24[["Jahr\nGemeinden", "Unnamed: 1", "Gewerbesteuer Hebesatz"]]
df24.columns = ["raw", "name", "hebesatz"]
df24["raw"] = df24["raw"].astype(str).str.strip()
df24["name"] = df24["name"].astype(str).str.strip()
df24["hebesatz"] = pd.to_numeric(df24["hebesatz"], errors="coerce")
df24 = df24[df24["hebesatz"].notna() & (df24["raw"] != "nan")].copy()

# gepolsterter 8-stelliger Schlüssel (nur für Ziffern-Codes sinnvoll)
df24["ags8"] = np.where(
    df24["raw"].str.isdigit(),
    df24["raw"].str.ljust(8, "0"),
    df24["raw"]                    # "DG" bleibt "DG"
)
df24["level"] = [classify_level(r, p) for r, p in zip(df24["raw"], df24["ags8"])]
df24["year"] = 2024
df24["hebesatz_source"] = "2024_destatis"
df24 = df24.drop_duplicates(subset=["ags8"], keep="first")


########################################################################
# 3) Jahr 2025 aus der CSV  (nur Gemeinde-Ebene; gemeldet = absolut)
########################################################################

df25 = pd.read_csv(
    CSV25, sep=";", skiprows=2, header=None, encoding="cp1252",
    names=["datum", "raw", "name", "grA", "grB", "grC", "gew"], dtype=str
)
df25 = df25[df25["datum"] == "30.06.2025"].copy()
df25["ags8"] = df25["raw"].str.zfill(8)
df25["name"] = df25["name"].astype(str).str.strip()
df25["gew"] = pd.to_numeric(df25["gew"], errors="coerce")
df25_changes = df25[df25["gew"].notna()][["ags8", "gew"]].drop_duplicates("ags8")

# 2025er Gemeinde-Universum = 2024er Gemeinden
g24 = df24[df24["level"] == "gemeinde"][["ags8", "name", "hebesatz"]].rename(
    columns={"hebesatz": "h2024"}
)
m25 = g24.merge(df25_changes, on="ags8", how="left")
m25["hebesatz"] = m25["gew"].where(m25["gew"].notna(), m25["h2024"])
m25["hebesatz_source"] = np.where(
    m25["gew"].notna(), "2025_gemeldet", "2025_fortgeschrieben"
)
m25["level"] = "gemeinde"
m25["year"] = 2025
df25_final = m25[["ags8", "name", "hebesatz", "level", "year", "hebesatz_source"]]


########################################################################
# 4) Zusammenführen
########################################################################

keep = ["ags8", "year", "name", "hebesatz", "level", "hebesatz_source"]
combined = pd.concat(
    [dta.reindex(columns=list(dta.columns)),
     df24[keep], df25_final[keep]],
    ignore_index=True
)

# abgeleitete Schlüssel
combined["ags_num"] = pd.to_numeric(combined["ags8"], errors="coerce").astype("Int64")
combined["state"] = combined["ags8"].str[:2]
combined["kreis"] = combined["ags8"].str[:5]

# Namen je AGS auffüllen (falls in 2024/25-Zeilen andere Schreibweise/leer)
combined["name"] = combined.groupby("ags8")["name"].transform(lambda s: s.ffill().bfill())

combined = combined.sort_values(["level", "ags8", "year"]).reset_index(drop=True)
combined.to_csv(OUT_LONG, index=False, encoding="utf-8-sig")


########################################################################
# 5) Breite Gemeinde-Tabelle (ein Jahr je Spalte)
########################################################################

gem = combined[combined["level"] == "gemeinde"].copy()
wide = gem.pivot_table(index="ags8", columns="year", values="hebesatz", aggfunc="first")
names = gem.dropna(subset=["name"]).groupby("ags8")["name"].last()
wide.insert(0, "name", names)
wide.to_csv(OUT_WIDE, encoding="utf-8-sig")


########################################################################
# 6) Report
########################################################################

print("=== Geschrieben ===")
print(OUT_LONG)
print(OUT_WIDE)
print()
print("Langes Panel: %d Zeilen, Jahre %s-%s"
      % (len(combined), int(combined['year'].min()), int(combined['year'].max())))
print()
print("Ebenen (level) im Gesamtpanel:")
print(combined["level"].value_counts())
print()
print("Gemeinden je Jahr (nur level==gemeinde) und fehlende Hebesätze:")
gy = combined[combined["level"] == "gemeinde"]
for y in [2021, 2022, 2023, 2024, 2025]:
    s = gy[gy["year"] == y]
    print("  %d: %6d Gemeinden, fehlend: %d" % (y, len(s), int(s['hebesatz'].isna().sum())))
print()
print("Herkunft der 2025er Werte:")
print(df25_final["hebesatz_source"].value_counts())
print()
print("Aggregat-Zeilen 2024 (in eigener 'level'-Kategorie erhalten):")
agg = df24[df24["level"] != "gemeinde"]
print(agg["level"].value_counts())
print("Deutschland-Gesamt (DG) 2024 Hebesatz:",
      df24.loc[df24["level"] == "bund", "hebesatz"].values)
