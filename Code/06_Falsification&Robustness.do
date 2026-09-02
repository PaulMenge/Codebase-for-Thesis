/*******************************************************************************
* 06 Falsification and Robustness Checks Do-File
*******************************************************************************/
use "${final_data_dir}\IBS_Firm_Level_merged.dta", clear

capture program drop hc
program hc
	qui count if e(sample)
	local n=r(N)
	qui count if e(sample) & hike==1
	local h1=r(N)
	qui count if e(sample) & hike==0
	di as res "N=`n'  hike1=`h1'  hike0=" r(N)
end

//RESTRICT TO 2024/2025 hereafter:
count if inrange(year, 2024, 2025) & !missing(lbt_change) & !missing(revborr) & month == 11

keep if inrange(year, 2024, 2025) & month == 11

keep if anticipated!=1 // OMIT ANTICIPATED ONES

keep if shielded != 1  // OMIT SHIELDED ONES




**Appendx/ Further Tests



*Continuous and Dummy for Branches:
*Commerce:
reghdfe revborr lbt_change if comm==1, vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if comm==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if comm==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr lbt_change ln_emp if comm==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change ln_emp lbt_nov_lagged if comm==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe revborr hike if comm==1, vce(cluster plz_kgs)
hc
reghdfe revborr hike if comm==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr hike if comm==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if comm==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr hike ln_emp lbt_nov_lagged if comm==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if comm==1, vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if comm==1, vce(cluster plz_kgs)
hc

*Services:
reghdfe revborr lbt_change if serv==1, vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if serv==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if serv==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr lbt_change ln_emp if serv==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change ln_emp lbt_nov_lagged if serv==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe revborr hike if serv==1, vce(cluster plz_kgs)
hc
reghdfe revborr hike if serv==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr hike if serv==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if serv==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr hike ln_emp lbt_nov_lagged if serv==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if serv==1, vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if serv==1, vce(cluster plz_kgs)
hc

*Manufacturing
reghdfe revborr lbt_change if manu==1, vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if manu==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if manu==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr lbt_change ln_emp if manu==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change ln_emp lbt_nov_lagged if manu==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe revborr hike if manu==1, vce(cluster plz_kgs)
hc
reghdfe revborr hike if manu==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr hike if manu==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if manu==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr hike ln_emp lbt_nov_lagged if manu==1, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if manu==1, vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if manu==1, vce(cluster plz_kgs)
hc




*Regressions accounting for investment: inv_stable_all/nochange == 1
reghdfe revborr rev_invest //Co-Movement of investment and borrowing revisions
hc
*Use for regression only firms which said invest_dj is "2" and in y-1 invest_nj was also "2" (not changed).
tab inv_stable_all, missing
tab inv_stable_nochange, missing
count if inv_stable_nochange == 1 & !missing(revborr, lbt_change)

*for all non-changed investment forecast (forecasting same, realized same)
reghdfe revborr hike if inv_stable_nochange == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_stable_nochange == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_stable_nochange == 1, absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if inv_stable_nochange == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if inv_stable_nochange == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if inv_stable_nochange == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if inv_stable_nochange == 1, absorb(year) vce(cluster plz_kgs)
hc

*for generally the same investment forecast (forecast and realized lower/same/higher)
reghdfe revborr hike if inv_stable_all == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_stable_all == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_stable_all == 1, absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if inv_stable_all == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if inv_stable_all == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if inv_stable_all == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if inv_stable_all == 1, absorb(year) vce(cluster plz_kgs)
hc


*Instead as Control, with flexible entry of investment dynamics:
reghdfe revborr hike i.invest_nj_lagged i.invest_dj, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike i.invest_nj_lagged i.invest_dj, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike i.invest_nj_lagged i.invest_dj, absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike i.invest_nj_lagged i.invest_dj, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp i.invest_nj_lagged i.invest_dj, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut i.invest_nj_lagged i.invest_dj, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut i.invest_nj_lagged i.invest_dj, absorb(year) vce(cluster plz_kgs)
hc


*Instead with regressions accounting for planned stable investment: inv_stable == 1
count if inv_planned_stable == 1 & !missing(revborr, lbt_change)

reghdfe revborr hike if inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1, absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if inv_planned_stable == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if inv_planned_stable == 1, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if inv_planned_stable==1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if inv_planned_stable==1, absorb(year) vce(cluster plz_kgs)
hc


*Omitting firms with no planned external borrowing NEW
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc



*Both firms with non-zero planned external borrowing AND constant investment plans NEW
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc

tab cut  if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged)

*All of those inconclusive!!










*Size
preserve
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch)

reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc


reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc

restore


preserve
keep if Unternehmen_besch<100 & !missing(Unternehmen_besch)

reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc


reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc

restore






*Size x Industry

preserve
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch) & manu == 1

reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc
restore

preserve
keep if empl_size == "medium" & manu != 1

reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc
restore
preserve
keep if empl_size != "large" & manu != 1

reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit year) vce(cluster plz_kgs)
hc
restore




*For lbtchange levels: if cut is taken out of the regression:

*Now for levels in percentages (as 1% lbt is coded in the data as 1 for lbt_change)
preserve
keep if empl_size == "large" & manu == 1 & cut == 0

reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down lbt_change cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up lbt_change cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc


reghdfe revborr lbt_change if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
restore


preserve
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch) & manu == 1 & cut == 0

reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down lbt_change cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up lbt_change cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc


reghdfe revborr lbt_change if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
restore

preserve
keep if empl_size == "medium" & manu != 1 & cut == 0

reghdfe revborr lbt_change if lbt_change >-0.00001 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down lbt_change cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up lbt_change cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs) //interesting
hc


reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
restore













*For Manufacturing Firms where capital investment was one of the planned goals (invgoals_nj_cap_lagged != 0)
preserve
keep if inlist(year, 2024, 2025)
keep if manu == 1 & invgoals_nj_cap_lagged == 0 & !missing(invgoals_nj_cap_lagged)
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc

tab cut  if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged)
restore


*For LARGE Manufacturing Firms where capital investment was one of the planned goals (invgoals_nj_cap_lagged != 0)
preserve
keep if inlist(year, 2024, 2025)
keep if manu == 1 & invgoals_nj_cap_lagged == 0 & !missing(invgoals_nj_cap_lagged) & Unternehmen_besch > 100
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr hike ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr hike lbt_nov_lagged ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc

tab cut  if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged)
restore




*Without Dummies
*Omitting firms with no planned external borrowing
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc
reghdfe revborr lbt_change ln_emp if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change lbt_nov_lagged ln_emp if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

*Both firms with no planned external borrowing and constant investment plans
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & inv_planned_stable == 1, absorb(sector_wz08_4digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & inv_planned_stable == 1, absorb(sector_wz08_4digit) vce(cluster bundesland)
hc
reghdfe revborr lbt_change ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1, absorb(sector_wz08_4digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change lbt_nov_lagged ln_emp if borrcap_ny_lagged != 0 & inv_planned_stable == 1, absorb(sector_wz08_4digit) vce(cluster plz_kgs)
hc

reghdfe rev_down lbt_change if borrcap_ny_lagged != 0 & inv_planned_stable == 1, vce(cluster plz_kgs)
hc





*Falsicfication via Lead Lag Hike Placebos

tab hike hike_lag
corr hike hike_lag

reghdfe revborr hike_lag if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lag if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="medium", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike_lag hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lag hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="medium", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike_lag hike if manu==1 & empl_size == "large" & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lag hike if manu==1 & Unternehmen_besch>100 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lag hike if manu!=1 & empl_size=="medium" &  inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="medium", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
*No lagged effects apparently



tab hike hike_lead // ONLY FOR 2024! becuase 2026 change not there yet
corr hike hike_lead

reghdfe revborr hike_lead if !missing(revborr)
hc
reghdfe revborr hike_lead if manu==1 & empl_size=="large" &  inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lead if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike_lead hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike_lead hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike_lead hike if manu==1 & empl_size == "large" & inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lead hike if manu==1 & Unternehmen_besch>100 & inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike_lead hike if manu!=1 & empl_size!="large" & inv_planned_stable == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc







gen byte lead24 = (hike_lead==1 & year == 2024 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & month == 11)
gen byte hit25 = (hike==1 & year == 2025 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & month == 11)
bysort firm_id: egen ever_lead24= max(lead24)
bysort firm_id: egen ever_hit25= max(hit25)

distinct firm_id if ever_lead24 == 1
distinct firm_id if ever_lead24 == 1 & ever_hit25 == 1
distinct firm_id if ever_lead24 == 1 & ever_hit25 == 1 & hike == 1

distinct firm_id if ever_lead24 == 1 & ever_hit25 == 1 & manu==1
distinct firm_id if ever_lead24 == 1 & ever_hit25 == 1 & manu!=1
//That makes the Placebo Test somewhat powerless as the same firms that are in the treated sample for 2024 are also in that of 2025 as many municipalitites hike two times in a row (not multi year regime though). Panel Persistenc, and the placebo would need the lead group to be cleanly treated contemporaneously. 




*Randomization:


gen byte grp = manu == 1

global cell1 `"grp == 1 & Unternehmen_besch>100 & !missing(Unternehmen_besch) & inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged)"'
global cell0 `"grp == 0 & empl_size != "large" & inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged)"'
global Rife "absorb(year sector_wz08_2digit) vce(cluster plz_kgs)"

egen plzyear = group(plz_kgs year)

foreach g in 1 0{
	preserve
	keep if ${cell`g'}
	reghdfe revborr hike, $Rife 
	hc
	ritest hike _b[hike] if ${cell`g'}, cluster(plzyear) reps(100) seed(20260730) : reghdfe revborr hike, $Rife
	restore
}
************