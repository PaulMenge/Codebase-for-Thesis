/*******************************************************************************
* 03 Analysis Do-File
For more analysis regaring underlying data and merges with lbt please run 01_merge_with_checks.do instead of 01_merge.de
*******************************************************************************/
use "${final_data_dir}\IBS_Firm_Level_merged.dta", clear

tabstat Unternehmen_besch turnover_quant_ly inv_quant_ly lbt_curr if inlist(year, 2024, 2025) & month== 3, stat(p10 p25 p50 p75 p90 mean) columns(statistics)
tabstat Unternehmen_besch turnover_quant_ly inv_quant_ly lbt if inlist(year, 2024, 2025) & inv_planned_stable == 1 & month== 3, stat(p10 p25 p50 p75 p90 mean) columns(statistics)
tabstat Unternehmen_besch turnover_quant_ly inv_quant_ly lbt if inlist(year, 2024, 2025) & inv_planned_stable == 1 &  borrcap_ny_lagged != 0 & month== 3, stat(p10 p25 p50 p75 p90 mean) columns(statistics)

tabstat Unternehmen_besch turnover_quant_ly inv_quant_ly lbt if inlist(year, 2024, 2025) & inv_planned_stable == 1 & manu == 1 &  borrcap_ny_lagged != 0 & month== 3, stat(p10 p25 p50 p75 p90 mean) columns(statistics)
tabstat Unternehmen_besch turnover_quant_ly inv_quant_ly lbt if inlist(year, 2024, 2025) & inv_planned_stable == 1 & manu!= 1 &  borrcap_ny_lagged != 0 & month== 3, stat(p10 p25 p50 p75 p90 mean) columns(statistics)

*Data Overview:
*firms and lbt
tab date_m if inlist(year, 2023, 2024, 2025)
tab month if missing(lbt) & year == 2025
tab month if !missing(lbt) & year == 2025
tab month if missing(lbt) & year == 2024
tab month if !missing(lbt) & year == 2024
tab month if missing(lbt) & year == 2023
tab month if !missing(lbt) & year == 2023

preserve 
keep plz_kgs year lbt
duplicates drop
keep if inlist(year, 2023, 2024, 2025)
reshape wide lbt, i(plz_kgs) j(year)
gen changed = lbt2023 != lbt2024 != lbt2025 & !missing(lbt2023) & !missing(lbt2024) & !missing(lbt2024)
tab changed
restore


/////lbt changes
*Overview
tabstat lbt_change, by(year) stat(mean median)
sum lbt_change if year == 2024 & month == 11, detail
sum lbt_change if year == 2025 & month == 11, detail

*any changes of lbt after January?
preserve
gen lbt_jan24 = lbt_change if inlist(year, 2024, 2025) & month == 11
bysort plz_kgs (lbt_jan24): egen lbt_jan24_fill = max(lbt_jan24)
gen mid_year_change = lbt_change != lbt_jan24_fill if inlist(year, 2023, 2024, 2025) & month == 11
tab mid_year_change
*list firm_id plz_kgs lbt_jan24_fill lbt_change if mid_year_change != 0 & !missing(mid_year_change)
restore

	*Distribution of lbt_changes and firms
	preserve
	keep if month ==11 & year == 2024
	bysort plz_kgs: gen n_firms = _N
	duplicates drop plz_kgs, force
	keep gemeinde plz_kgs n_firms lbt_change

	tab lbt_change, missing
	count if lbt_change != 0 & !missing(lbt_change)

	*Top 20 plz
	gsort -n_firms
	list plz_kgs gemeinde n_firms lbt_change in 1/20, sep(0)

	*Top 20 plz in non-zero lbt changes
	keep if lbt_change != 0 & !missing(lbt_change)
	gsort -n_firms
	list plz_kgs gemeinde n_firms lbt_change in 1/20, sep(0)

	restore


		*Distribution of lbt_changes and firms
	preserve
	keep if month ==11 & year == 2025
	bysort plz_kgs: gen n_firms = _N
	duplicates drop plz_kgs, force
	keep gemeinde plz_kgs n_firms lbt_change

	tab lbt_change, missing
	count if lbt_change != 0 & !missing(lbt_change)

	*Top 20 plz
	gsort -n_firms
	list plz_kgs gemeinde n_firms lbt_change in 1/20, sep(0)

	*Top 20 plz in non-zero lbt changes
	keep if lbt_change != 0 & !missing(lbt_change)
	gsort -n_firms
	list plz_kgs gemeinde n_firms lbt_change in 1/20, sep(0)

	restore
	
		*Distribution of lbt_changes and firms
	preserve
	keep if month ==11 & inlist(year, 2024, 2025) & !missing(plz_kgs)
	bysort plz_kgs: gen n_firms = _N
	duplicates drop plz_kgs, force
	keep gemeinde plz_kgs n_firms lbt_change

	tab lbt_change, missing
	count if lbt_change != 0 & !missing(lbt_change)

	*Top 20 plz
	gsort -n_firms
	list plz_kgs gemeinde n_firms lbt_change in 1/20, sep(0)

	*Top 20 plz in non-zero lbt changes
	keep if lbt_change != 0 & !missing(lbt_change)
	gsort -n_firms
	list plz_kgs gemeinde n_firms lbt_change in 1/20, sep(0)

	restore
	
	*In which states are most firms and what are there changes?
preserve
 	keep if month ==11 & inlist(year, 2024, 2025) & !missing(lbt_change)
	capture drop bl
		capture drop one
	capture tsset, clear
	capture stset, clear
	encode bundesland, gen(bl)	
	bysort bl firm_id: gen first = _n == 1
	bysort bl: egen n_firms = total(first)
	
	duplicates drop plz_kgs, force
	gen one = 1
	gen changed = lbt_change != 0
	gen change_if_chg = lbt_change if changed
	
	collapse (sum) n_plz = one (mean) n_firms = n_firms (sum) n_chg = changed (mean) mean_chg = change_if_chg (p50) med_chg = change_if_chg (mean) mean_all = lbt_change, by(bl)
	
	gen share_chg= n_chg/n_plz
	
	order bl n_plz n_firms n_chg share_chg mean_chg med_chg mean_all
	drop if missing(bl)
	sort mean_chg
	list, sep(0) noobs
restore



********************************************************************************
* Borrowing revisions overview
********************************************************************************

/*
sum borrcap_ny if year == 2023 & month == 11, detail
sum borrcap_ly if year == 2024 & month == 11, detail
sum borrcap_ly if year == 2025 & month == 11, detail

table year month, stat (mean revborr)
sum revborr if year == 2025 & month == 11, detail
sum revborr if revborr != 0 & year == 2025 & month == 11
sum revborr if year == 2025 & month == 11, detail
sum revborr if revborr != 0 & year == 2025 & month == 11


*PLZ with nonzero change in 2024, 2025
preserve
	keep if year == 2024 & month == 11 & lbt_change != 0 & !missing(lbt_change)
	keep year plz_kgs bundesland kreis gemeinde lbt_change lbt lbt_lag_1 lbt_lag_2 lbt_lag_3 lbt_lag_4 lbt_lag_5 lbt_lag_6 lbt_lag_7 lbt_lag_8
	duplicates drop
	export delimited using "${output_dir}\2024_lbt_change_check.md", replace
	list year plz_kgs bundesland kreis gemeinde lbt_change lbt lbt_lag_1 lbt_lag_2 lbt_lag_3 lbt_lag_4 lbt_lag_5 lbt_lag_6 lbt_lag_7 lbt_lag_8, clean noobs
restore
preserve
	keep if year == 2025 & month == 11 & lbt_change != 0 & !missing(lbt_change)
	keep year plz_kgs bundesland kreis gemeinde lbt_change lbt lbt_lag_1 lbt_lag_2 lbt_lag_3 lbt_lag_4 lbt_lag_5 lbt_lag_6 lbt_lag_7 lbt_lag_8
	duplicates drop
	export delimited using "${output_dir}\2025_lbt_change_check.md", replace
	list year plz_kgs bundesland kreis gemeinde lbt_change lbt lbt_lag_1 lbt_lag_2 lbt_lag_3 lbt_lag_4 lbt_lag_5 lbt_lag_6 lbt_lag_7 lbt_lag_8, clean noobs
restore

*/
reghdfe revborr rev_invest if month == 11, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) //Co-Movement of investment and borrowing revisions
reghdfe inv_change invest_nj_lagged_r, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) //Forecasting accuracy of the self reported plans




********************************************************************************
* 2024 & 2025 plots
********************************************************************************

keep if inlist(year, 2024, 2025) & month == 11
gen byte mgrp = (manu==1)
count
distinct firm_id
distinct plz_kgs

*Binscatter Baseline
preserve 
keep if !missing(lbt_change) & !missing(revborr)
collapse (mean) revborr lbt_change (count) n=revborr, by(plz_kgs)
twoway (scatter revborr lbt_change [w=n], msymbol(oh) mcolor(navy%50)) (lfit revborr lbt_change [w=n], lcolor(cranberry)), title("Pooled by Municipality") xtitle("LBT Change in percent") ytitle("Mean Revision in rel. investment financed by borrowing") legend(off)
graph export "${output_dir}/Plot1_revborr_lbt.png", replace
restore

preserve 
keep if !missing(lbt_change) & !missing(revborr) & lbt_change!=0
collapse (mean) revborr (count) n=revborr, by(lbt_change)
twoway (scatter revborr lbt_change [w=n], msymbol(oh) mcolor(navy%50)) (lfit revborr lbt_change [w=n], lcolor(cranberry)), title("Non-Zero LBT Change") xtitle("LBT Change in percent") ytitle("Mean Revision in borrowing") legend(off)
graph export "${output_dir}/Plot2_NonZero_revborr_lbt.png", replace
restore

preserve
keep if !missing(lbt_change) & !missing(revborr) & lbt_change!=0 & inv_planned_stable==1
collapse (mean) revborr (count) n=revborr, by(lbt_change mgrp)
twoway (scatter revborr lbt_change if mgrp==1 [w=n], msymbol(oh) mcolor(cranberry%60)) (scatter revborr lbt_change if mgrp==0 [w=n], msymbol(oh) mcolor(navy%60)) (lfit revborr lbt_change if mgrp==1 [w=n], lcolor(cranberry)) (lfit revborr lbt_change if mgrp==0 [w=n], lcolor(navy)), title("Non-Zero LBT Change: planned investment stable") xtitle("LBT Change in percent") ytitle("Mean Revision in borrowing") legend(order(1 "Manufacturing" 2 "Non-Manufacturing"))
graph export "${output_dir}/Plot3_NonZero_revborr_lbt_invstable.png", replace
restore

preserve
keep if !missing(lbt_change) & !missing(revborr) & lbt_change!=0 & borrcap_ny_lagged!=0 & !missing(borrcap_ny_lagged)
collapse (mean) revborr (count) n=revborr, by(lbt_change mgrp)
twoway (scatter revborr lbt_change if mgrp==1 [w=n], msymbol(oh) mcolor(cranberry%60)) (scatter revborr lbt_change if mgrp==0 [w=n], msymbol(oh) mcolor(navy%60)) (lfit revborr lbt_change if mgrp==1 [w=n], lcolor(cranberry)) (lfit revborr lbt_change if mgrp==0 [w=n], lcolor(navy)), title("Non-Zero LBT Change: nonzero planned borrowing") xtitle("LBT Change in percent") ytitle("Mean Revision in borrowing") legend(order(1 "Manufacturing" 2 "Non-Manufacturing"))
graph export "${output_dir}/Plot4_NonZero_revborr_lbt_borrnonzero.png", replace
restore

preserve
keep if !missing(lbt_change) & !missing(revborr) & lbt_change!=0 & inv_planned_stable==1 & borrcap_ny_lagged!=0 & !missing(borrcap_ny_lagged)
collapse (mean) revborr (count) n=revborr, by(lbt_change mgrp)
twoway (scatter revborr lbt_change if mgrp==1 [w=n], msymbol(oh) mcolor(cranberry%60)) (scatter revborr lbt_change if mgrp==0 [w=n], msymbol(oh) mcolor(navy%60)) (lfit revborr lbt_change if mgrp==1 [w=n], lcolor(cranberry)) (lfit revborr lbt_change if mgrp==0 [w=n], lcolor(navy)), title("Non-Zero LBT Change: stable Inv. & nonzero Borr. plans") xtitle("LBT Change in percent") ytitle("Mean Revision in borrowing") legend(order(1 "Manufacturing" 2 "Commerce and Services"))
graph export "${output_dir}/Plot5_NonZero_revborr_lbt_both.png", replace
restore


preserve
keep if !missing(rev_invest) & !missing(revborr)
collapse (mean) revborr (semean) se=revborr, by(rev_invest)
gen hi=revborr+1.96*se
gen low=revborr-1.96*se
twoway (bar revborr rev_invest, barwidth(0.6) color(navy%70)) (rcap hi lo rev_invest, lcolor(black)), xtitle("X") ytitle("Y") xlabel(-2 -1 0 1 2) legend(off) title("Comovement of Investment and Borrowing Revisions") xtitle("Investment Revs") ytitle("Borrowing Revs (percent)")
graph export "${output_dir}/comovement_inv_borr_revs.png", replace
restore

************