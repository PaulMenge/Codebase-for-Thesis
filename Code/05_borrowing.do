/*******************************************************************************
* 05 Borrowing Regression Do-File
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


distinct firm_id if hike == 1 & year == 2025 & !missing(lbt_change) & !missing(revborr)
distinct firm_id if hike == 0 & year == 2025 & !missing(lbt_change) & !missing(revborr)
distinct firm_id if hike == 1 & year == 2024 & !missing(lbt_change) & !missing(revborr)
distinct firm_id if hike == 0 & year == 2024 & !missing(lbt_change) & !missing(revborr) 

distinct plz_kgs if hike == 1 & year == 2025 & !missing(lbt_change) & !missing(revborr)
distinct plz_kgs if hike == 0 & year == 2025 & !missing(lbt_change) & !missing(revborr)
distinct plz_kgs if hike == 1 & year == 2024 & !missing(lbt_change) & !missing(revborr)
distinct plz_kgs if hike == 0 & year == 2024 & !missing(lbt_change) & !missing(revborr)


*For Small firms not sufficient data.
count if manu != 1 & !missing(lbt_change) & !missing(revborr)
count if manu == 1 & !missing(lbt_change) & !missing(revborr)

count if empl_size == "small"
count if empl_size == "medium"
count if empl_size == "large"
count if empl_size == "large" & manu == 1
count if empl_size == "medium" &  manu == 1
count if empl_size == "large" & manu != 1
count if empl_size == "medium" &  manu != 1

*Borrowing behaviour overview
count if borrcap_ly != 0 & !missing(borrcap_ly)
distinct firm_id if borrcap_ly != 0 & !missing(borrcap_ly)
count if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged)
distinct firm_id if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged)
tabstat borrcap_ly borrcap_ny_lagged revborr if borrcap_ly != 0 & !missing(borrcap_ly), stat(n mean p10 p25 p50 p75 p90) columns(statistics)
tabstat borrcap_ly borrcap_ny_lagged revborr if borrcap_ly != 0 & !missing(borrcap_ly), by(manu) stat(n mean p10 p50 p90) columns(statistics)





*Lean Regression, clustering in municipality
reghdfe revborr hike, absorb(year firm_id) vce(cluster plz_kgs)
hc

*Sector FE
reghdfe revborr hike, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

*Cluster in State for state-wide policy shocks etc
reghdfe revborr hike, absorb(sector_wz08_2digit year) vce(cluster bundesland)
hc

*with firm-level employment control
reghdfe revborr hike ln_emp, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

*Maybe to control for local economic conditions: ly lbt also
reghdfe revborr hike lbt_nov_lagged ln_emp, absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut, absorb(year) vce(cluster plz_kgs)
hc


*With non-Dummy lbt changes:
*LPM Ladder
reghdfe revborr lbt_change, vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe revborr lbt_change ln_emp, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe revborr lbt_change ln_emp lbt_nov_lagged, absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc




*Seems to be a composition story, thus for manufacturing:
preserve
keep if manu == 1 
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

*For Comm, Serv, as they behave similarly here as opposed to manu:
preserve
keep if manu != 1 & !missing(survey)
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






*FOR FIRM'S SIZE
preserve
keep if empl_size == "large"

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
keep if empl_size == "medium" 

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




*Interaction of size and industry
preserve
keep if empl_size == "large" & manu == 1

reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc


reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
restore

preserve
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch) & manu == 1

reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc


reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 &!missing(borrcap_ny_lagged), absorb(sector_wz08_2digit year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe rev_up hike cut if borrcap_ny_lagged != 0 & inv_planned_stable == 1 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
restore

preserve
keep if empl_size == "medium" & manu != 1 

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
keep if empl_size != "large" & manu != 1 

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



reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & Unternehmen_besch<100, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0  & Unternehmen_besch<100 & !missing(Unternehmen_besch), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & Unternehmen_besch>100 & !missing(Unternehmen_besch), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc



*Now for levels in percentages (as 1% lbt is coded in the data as 1 for lbt_change)
preserve
keep if empl_size == "large" & manu == 1

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
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch) & manu == 1

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
keep if empl_size == "medium" & manu != 1

reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
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
preserve
keep if empl_size != "large" & manu != 1 

reghdfe revborr lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year) vce(cluster plz_kgs)
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





*Rechtsformen
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size!="small", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if  manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size!="small", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & empl_size=="medium", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc


count if hike == 1 & manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & empl_size=="large"
count if hike == 0 & manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & empl_size=="large"
count if hike == 1 & manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & empl_size!="large"
count if hike == 0 & manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & empl_size!="large"




//EVTL FOR BUSINESS STATE
count if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & statebus==0 & empl_size!="small" & hike == 1

reghdfe revborr hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & statebus==0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & statebus==0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & inv_stable_all == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & inv_rev_down == 1 & borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & inv_rev_up == 1& borrcap_ny_lagged != 0, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & inv_stable_all == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & inv_rev_down == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & inv_rev_up == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc




reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & statebus==0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe revborr hike if manu!=1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & statebus==0 & empl_size!="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

*And expectations of it:
reghdfe revborr hike if manu==1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & comexp!=0 & empl_size=="large", absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc



//RECHTSFORMEN block
preserve
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch) & manu == 1
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc

restore

preserve
keep if empl_size == "medium" & manu == 1
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
restore

preserve
keep if Unternehmen_besch>100 & !missing(Unternehmen_besch) & manu != 1
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
restore

preserve
keep if empl_size == "medium" & manu != 1
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc

restore
preserve
keep if empl_size != "large" & manu != 1
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe revborr hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc

reghdfe rev_down hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe rev_up hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & rechtsform == 1, absorb(year) vce(cluster plz_kgs)
hc

restore
*****