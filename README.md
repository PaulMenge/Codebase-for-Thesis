# Online Appendix: Firms’ Investment and Borrowing Responses to Tax Hikes

This repository contains the empirical code and the corresponding tables and figures for the online appendix to *Firms’ Investment and Borrowing Responses to Tax Hikes*.

## Repository structure

```text
.
├── Code/
│   ├── main.do
│   ├── 01_merge.do
│   ├── 01_merge_withcheck.do
│   ├── 02_var_prep.do
│   ├── 03_analysis.do
│   ├── 04_investment.do
│   ├── 05_borrowing.do
│   └── 06_Falsification&Robustness.do
├── Figures/
│   ├── Plot1_revborr_lbt.png
│   ├── Plot2_NonZero_revborr_lbt.png
│   ├── Plot3_NonZero_revborr_lbt_invstable.png
│   ├── Plot4_NonZero_revborr_lbt_borrnonzero.png
│   ├── Plot5_NonZero_revborr_lbt_both.png
│   └── comovement_inv_borr_revs.png
├── Tables/
│   ├── Table_PanelRevInvestDirectional.tex
│   ├── rev_invest_byyear.tex
│   └── rev_invest_directional.tex
├── .gitignore
└── README.md
```

## File registry

### Code

| File | Purpose |
| --- | --- |
| `main.do` | Master script. Defines project paths, creates expected working directories, and runs the replication workflow in order. |
| `01_merge.do` | Merges firm-level survey data with municipal local-business-tax data for 2003–2025. |
| `01_merge_withcheck.do` | Alternative merge script with additional merge diagnostics; use for validating match quality. |
| `02_var_prep.do` | Constructs analysis variables, including local-business-tax changes, treatment indicators, sector indicators, investment measures, and financing variables. |
| `03_analysis.do` | Produces descriptive analyses and diagnostics for the merged data and tax changes. |
| `04_investment.do` | Estimates the investment-response specifications. |
| `05_borrowing.do` | Estimates the borrowing-response specifications. |
| `06_Falsification&Robustness.do` | Runs falsification exercises, robustness checks, and sector-specific specifications. |

### Figures

| File | Content |
| --- | --- |
| `Plot1_revborr_lbt.png` | Borrowing-revision outcome by local-business-tax change. |
| `Plot2_NonZero_revborr_lbt.png` | Borrowing-revision outcome for non-zero tax changes. |
| `Plot3_NonZero_revborr_lbt_invstable.png` | Non-zero tax changes, restricted to firms with stable planned investment. |
| `Plot4_NonZero_revborr_lbt_borrnonzero.png` | Non-zero tax changes, restricted to firms reporting non-zero borrowing. |
| `Plot5_NonZero_revborr_lbt_both.png` | Non-zero tax changes with the combined sample restrictions. |
| `comovement_inv_borr_revs.png` | Co-movement of investment and borrowing revisions. |

### Tables

| File | Content |
| --- | --- |
| `Table_PanelRevInvestDirectional.tex` | Panel table for directional investment revisions. |
| `rev_invest_byyear.tex` | Investment-revision results by year. |
| `rev_invest_directional.tex` | Directional investment-revision results. |

## Reproduction

1. Install Stata and the user-written commands used by the scripts, including `reghdfe` and `distinct`.
2. Obtain access to the confidential firm-level EBDC data and place it in the project-specific data directories expected by `main.do`.
3. Obtain the municipal local-business-tax source files used in `01_merge.do`.
4. Update `root_dir` in `Code/main.do` to your local project directory, then run `main.do` from Stata.

The confidential microdata and externally sourced raw data are intentionally not included in this repository. The supplied code therefore documents the workflow but cannot be executed without the required data permissions and inputs.

## Notes

- `main.do` is the intended entry point; run individual scripts only when reproducing a specific stage.
- `01_merge_withcheck.do` is a diagnostic alternative to `01_merge.do`; do not run both as part of the same standard workflow.
- Generated datasets, logs, and temporary files are excluded through `.gitignore`.
