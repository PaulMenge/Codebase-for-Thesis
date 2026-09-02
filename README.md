# Online Appendix: Take a Hike: Firms’ Investment and Borrowing Responses to Corporate Tax Changes

This repository contains the empirical code and the corresponding tables and figures for the online appendix to *Take a Hike: Firms’ Investment and Borrowing Responses to Corporate Tax Changes*.

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

## Reproduction

The code has to be run on the servers of the EBDC on ifo Institute grounds. Required packages are installed. For working code execution, the lbt change file of the German Statistical Office as referenced in the thesis has to be supplied, alongside the firm type matching files of the center.

The confidential microdata and externally sourced raw data are intentionally not included in this repository. The supplied code therefore documents the workflow but cannot be executed without the required data permissions and inputs.

## Notes

- `main.do` is the intended entry point; run individual scripts only when reproducing a specific stage.
- `01_merge_withcheck.do` is a diagnostic alternative to `01_merge.do` and not targeted in main.do per the standard workflow.
