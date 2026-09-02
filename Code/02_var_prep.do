/*******************************************************************************
* Variable Prep Do-File
*Spawns: empl_size, perc_borrcap_ly/ny, to_change, inv_change, 
*******************************************************************************/

*Renaming Variables in Master
use "${final_data_dir}\IBS_Firm_Level_merged.dta", clear

*Combined lbt variable: (busitax in <= 2023, gewerbesteuerhebesatz in 2024)
gen lbt = busitaxm
replace lbt = GewerbesteuerHebesatz if year == 2024
replace lbt = gemeindehebesatz if year == 2025

*lbt change: Nov of this year- last year
preserve
keep if month == 11
keep plz_kgs year lbt
duplicates drop
replace year = year + 1 
rename lbt lbt_nov_lagged
recast double lbt_nov_lagged, force
tempfile lbtlag
save `lbtlag'
restore

merge m:1 plz_kgs year using `lbtlag', keep(1 3) nogen
gen lbt_change = lbt - lbt_nov_lagged if month == 11 & !missing(lbt) //NOT MISSING IS NEW
*drop lbt_nov_lagged
erase `lbtlag'


************************
*ONLY FOR THIS 2025 VERSION given limited tax change data:
replace lbt_change = 0 if missing(lbt_change) & year==2025 & month == 11
************************

count if month==11 & !missing(lbt_change)
tab lbt_change if year==2024 & month==11, missing
tab lbt_change if year==2025 & month==11, missing
codebook lbt_nov_lagged if month == 11

*Implement Lags (for research regarding hikes' surprise)
preserve
keep plz_kgs year lbt
drop if missing(plz_kgs) | missing(year)
duplicates drop
isid plz_kgs year
tempfile lbt_history
save `lbt_history'
restore

forvalues k = 1/8{
	preserve
	use `lbt_history', clear
	rename lbt lbt_lag_`k'
	replace year = year +`k'
	tempfile lag`k'
	save `lag`k''
	restore
	
	merge m:1 plz_kgs year using `lag`k'', keep(master match) nogen
}


*Dummy for positive tax change
capture gen byte lbt_increase = .
replace lbt_increase = 1 if lbt_change > 0 & !missing(lbt_change)
replace lbt_increase = 0 if lbt_change == 0

*Indicators Binary
capture drop anticipated
*Omit lbt changes which could have been anticipated through multi year regimes, covid snap backs or earlier than survey announcement
gen byte anticipated = 0
replace anticipated = 1 if month==11 & !missing(lbt_change) & year == 2025 & inlist(plz_kgs, 13071035, 5112000, 5114000, 5978036, 8118048, 8236072, 8417079, 9771130, 8416009)
replace anticipated = 1 if month==11 & !missing(lbt_change) & year == 2025 & inlist(plz_kgs, 3359010, 6438012)
replace anticipated = 1 if  month==11 & !missing(lbt_change) & year == 2024 & inlist(plz_kgs, 13071035, 1056032, 8326074, 3157006, 5314000, 3405000, 10044116, 8425139, 5170028, 8315113)


gen hike = (lbt_change > 0) if !missing(lbt_change) & anticipated == 0
gen cut = (lbt_change < 0) if !missing(lbt_change) & anticipated == 0



*Branches Binaries
gen comm = 1 if survey == "HAN"
gen serv = 1 if survey == "DIE"
gen manu = 1 if survey == "IND"
label var comm "Commerce Sector Dummy (Handel)"
label var serv "Service Sector Dummy (Dienstleistungen)"
label var manu "Manufacturing Sector Dummy (Industrie)"


*share of external finance for investment
ren perc_borrcap_23 borrcap_ly // % investm. financed w. borrowed capital this fiscal year
ren perc_borrcap_24 borrcap_ny // % investm. financed w. borrowed capital next fiscal year

*Add manufacturing VG data 
replace borrcap_ly = vg_perc_borrcap if manu == 1 &  inlist(year, 2023, 2024, 2025) & month==11 & !missing(vg_perc_borrcap)
replace borrcap_ny = vg_perc_borrcap_ny if manu == 1 &  inlist(year, 2023, 2024, 2025) & month==11 & !missing(vg_perc_borrcap_ny)


*Revisions rev_borr:
preserve
	keep if month == 11
	keep firm_id year borrcap_ny
	replace year = year + 1
	rename borrcap_ny borrcap_ny_lagged
	tempfile lag
	save `lag'
restore

merge m:1 firm_id year using `lag', keep(1 3) nogen

gen revborr= borrcap_ly - borrcap_ny_lagged if month == 11
erase `lag'

*Binaries:
gen rev_down = (revborr < 0) if !missing(revborr)
gen rev_up = (revborr > 0) if !missing(revborr)


/*
*Check if subsample of firms in revborr are different, looks good for invest, ln_emp and ln_age.
preserve
keep if year == 2024 & month == 11
count if !missing(borrcap_ly)  & !missing(borrcap_ny_lagged) *both
count if !missing(borrcap_ly)  & missing(borrcap_ny_lagged) *2023 forecast missing, maybe new entrant
count if missing(borrcap_ly)  & !missing(borrcap_ny_lagged) *had 2023 forecast but no 2024 ty entry
count if missing(borrcap_ly)  & missing(borrcap_ny_lagged) *neither
restore

*test for selection bias:
preserve
keep if year == 2024 & month == 11
gen attrited = missing(borrcap_ly)  & !missing(borrcap_ny_lagged)
reg attrited lbt_change, vce(cluster plz_kgs)

ttest invest_dj, by(attrited) *Others!
ttest ln_emp, by(attrited)
ttest ln_age, by(attrited)

restore

*drop borrcap_ny_lagged
*/

*Important for not getting "double format" issues anymore
recast double lbt_change lbt revborr, force

*size classes
gen empl_size = ""
replace empl_size = "small" if Unternehmen_besch < 50
replace empl_size = "medium" if inrange(Unternehmen_besch, 50, 249)
replace empl_size = "large" if Unternehmen_besch >= 250 & !missing(Unternehmen_besch)
encode empl_size, gen(es)

*average ln(employees) Dec 2018-2025
egen avg_emp = mean(Unternehmen_besch) if date_m <= ym(2025,12) & date_m >= ym(2018,12), by(firm_id)
gen ln_emp = ln(avg_emp)
gen ln_emp_w = ln_emp
sum ln_emp ,d
replace ln_emp_w = r(p1) if ln_emp_w < r(p1)
replace ln_emp_w = r(p99) if ln_emp_w < r(p99) & ln_emp_w != .
egen ln_emp_w_firm = max(ln_emp_w), by(firm_id)


*quant revenues (sales revenue/turnover) in EUR thous
gen turnover_quant_penuly = 0 if turnover_penuly_bil != . | turnover_penuly_mil != . | turnover_penuly_thous != .
replace turnover_quant_penuly = turnover_quant_penuly + (turnover_penuly_bil*1000000) if turnover_penuly_bil != .
replace turnover_quant_penuly = turnover_quant_penuly + (turnover_penuly_mil*1000) if turnover_penuly_mil != .
replace turnover_quant_penuly = turnover_quant_penuly + (turnover_penuly_thous) if turnover_penuly_thous != .

gen ln_turnover_quant_penuly = ln(turnover_quant_penuly)

gen turnover_quant_ly = 0 if turnover_lasty_bil != . | turnover_lasty_mil != . | turnover_lasty_thous != .
replace turnover_quant_ly = turnover_quant_ly + (turnover_lasty_bil*1000000) if turnover_lasty_bil != .
replace turnover_quant_ly = turnover_quant_ly + (turnover_lasty_mil*1000) if turnover_lasty_mil != .
replace turnover_quant_ly = turnover_quant_ly + (turnover_lasty_thous) if turnover_lasty_thous != .

gen ln_turnover_quant_ly = ln(turnover_quant_ly)
gen to_change = ln_turnover_quant_ly - ln_turnover_quant_penuly


*quant investment in EUR thous
gen inv_quant_penuly = 0 if inv_penuly_bil != . | inv_penuly_mil != . | inv_penuly_thous != .
replace inv_quant_penuly = inv_quant_penuly + (inv_penuly_bil*1000000) if inv_penuly_bil != .
replace inv_quant_penuly = inv_quant_penuly + (inv_penuly_mil*1000) if inv_penuly_mil != .
replace inv_quant_penuly = inv_quant_penuly + (inv_penuly_thous) if inv_penuly_thous != .

gen ln_inv_quant_penuly = ln(inv_quant_penuly)

gen inv_quant_ly = 0 if inv_lasty_bil != . | inv_lasty_mil != . | inv_lasty_thous != .
replace inv_quant_ly = inv_quant_ly + (inv_lasty_bil*1000000) if inv_lasty_bil != .
replace inv_quant_ly = inv_quant_ly + (inv_lasty_mil*1000) if inv_lasty_mil != .
replace inv_quant_ly = inv_quant_ly + (inv_lasty_thous) if inv_lasty_thous != .

gen ln_inv_quant_ly = ln(inv_quant_ly)

gen inv_change = ln_inv_quant_ly - ln_inv_quant_penuly
replace inv_change = -1 if inv_change < -1 & inv_change != .
replace inv_change = 3 if inv_change > 3 & inv_change != .




*investment expectations in survey; forecast investment stability 
preserve
	keep if month == 11
	keep firm_id year invest_nj
	replace year = year + 1
	rename invest_nj invest_nj_lagged
	tempfile invlag
	save `invlag'
restore

merge m:1 firm_id year using `invlag', keep(1 3) nogen

gen byte inv_planned_stable = (invest_nj_lagged == 2) // if month == 11 //forecast investment ly was "no change"

gen byte inv_stable_all= (invest_dj == invest_nj_lagged) if !missing(invest_dj) // if month == 11 //investment forecast wasn't altered
gen byte inv_stable_nochange= (invest_dj == 2 & invest_nj_lagged == 2) // if month == 11 //investment forecast wasn't altered & forecast was "no change"

label var inv_planned_stable "forecast investment ly was -no change-"
label var inv_stable_all "forecast investment = realized investment"
label var inv_stable_nochange "forecast investment = realized investment & forecast was -no change-"


*Recode them to -1 0 1 for lower, stable or higher investment for revisions building
foreach v of varlist invest_dj invest_nj_lagged {
	clonevar `v'_r = `v'
	recode `v'_r (1=1) (2=0) (3=-1)
	label var `v'_r "`v' recoded (1 higher, 0 same, -1 lower)"
}
gen rev_invest = invest_dj_r - invest_nj_lagged_r if month==11
label var rev_invest "Inv Rev, from 2 from lower to higher to -2 from higher to lower)"
gen inv_rev_down = (rev_invest < 0) if !missing(rev_invest)
gen inv_rev_up = (rev_invest > 0) if !missing(rev_invest)

/* Quick Overview
preserve
keep if year == 2024 & month == 11
tab inv_stable if missing(revborr), missing
count if inv_stable == 1 & missing(borrcap_ly)
count if inv_stable == 1 & missing(borrcap_ly_lagged)
count if inv_stable == 1 & missing(lbt_change)
restore
*/



*New for this data, with inspiration from Link et al: Quant. Downward Rev. Indicator & Log revisions ratio.
*for 2022: penuly and quantly togethet.
gen invchange_quant2022 = inv_quant_ly / inv_quant_penuly if year == 2023 //2024's stuff

preserve
	keep if year == 2023
	keep firm_id month year invchange_quant2022
	replace year = year - 1
	rename invchange_quant2022 invchange_quant_ly
	tempfile invchange_quant
	save `invchange_quant'
restore
merge m:1 firm_id month year using `invchange_quant', keep(1 3) nogen //2022
drop invchange_quant2022

*for 2023 onwards:
preserve
	keep if inlist(year, 2024, 2025) //evtl. + ,2026 when we have data
	keep firm_id month year inv_quant_ly
	replace year = year - 1
	rename inv_quant_ly inv_quant_ly_lead
	tempfile inv_quant_ly_lead
	save `inv_quant_ly_lead'
restore
merge m:1 firm_id month year using `inv_quant_ly_lead', keep(1 3) nogen

gen invchange_quant_202324 = inv_quant_ly_lead / inv_quant_ly if inlist(year, 2023, 2024) 
replace invchange_quant_ly = invchange_quant_202324 if !missing(invchange_quant_202324) & inlist(year, 2023, 2024)

gen inv_down_quant = (invchange_quant_ly < 1) if !missing(invchange_quant_ly) // Binary Downward Revision of Investment assuming ly was realized (in conj. with inv_planned_stable)
gen ln_invchange_quant_ly = ln(invchange_quant_ly) //Log Revision Ratio

*Winsorize the quant variable slightly (even though its already logged)
gen ln_invchange_quant_ly_win = ln_invchange_quant_ly
forval y = 2022/2024 {
	_pctile ln_invchange_quant_ly if year == `y', p(1 99)
	replace ln_invchange_quant_ly_win = r(r1) if ln_invchange_quant_ly_win < r(r1) & year == `y'
	replace ln_invchange_quant_ly_win = r(r2) if ln_invchange_quant_ly_win > r(r2) & year == `y' & !missing(ln_invchange_quant_ly_win)
}

tab month if !missing(inv_down_quant) & year == 2024 & inv_planned_stable == 1
*Get it to thewhole year s.t. it can be used in November regs:
bysort firm_id year: egen ln_invchange_quant_ly_filled= max(cond(month==3, ln_invchange_quant_ly, .))


* investment to revenue ratio (winsorized)
gen inv_revenue_penuly = inv_quant_penuly / turnover_quant_penuly
gen inv_revenue_ly = inv_quant_ly / turnover_quant_ly
gen inv_empl_penuly = inv_quant_penuly / avg_emp

replace inv_revenue_penuly = 1 if inv_revenue_penuly > 1 & inv_revenue_penuly != .

replace inv_revenue_ly = 1 if inv_revenue_ly > 1 & inv_revenue_ly != .

* winsorize investment ratio
tsset firm_id date_m
gen inv_revenue = f12.inv_revenue_ly
replace inv_revenue = f24.inv_revenue_penuly if year == 2021

gen inv_revenue_trim = inv_revenue
gen high_iratio = .


forval t = 2021/2025{  //to 2024 before
	sum inv_revenue if year == `t', d
	replace inv_revenue_trim  = . if inv_revenue > r(p95)  & inv_revenue != . & year == `t'
	replace inv_revenue_trim = . if inv_revenue < r(p5)  & inv_revenue != .  & year == `t'
	
	replace high_iratio = (inv_revenue > r(p75)) if inv_revenue != . & year == `t'
}

areg inv_revenue, absorb(firm_id)
predict inv_revenue_res, resid
gen high_iratio_firm = (inv_revenue_res > 0) if inv_revenue_res != .




*return on sales
gen ros = ros_surp
replace ros = - ros_loss if ros_loss >= 0 & ros == .
replace ros = -5 if ros < -5 & ros != .
replace ros = 20 if ros > 20 & ros != .

xtset firm_id date_m
gen l4_ros = l4.ros
gen ros_change = ros - l12.ros
egen ros_m	= mean(ros) if year <= 2025 & year >= 2023 //prior: 2021 to 2023
gen l_ros_m = l.ros_m

*equity ratio
egen eq_19_firm = max(cor9_eq1), by(firm_id)
egen eq_22_firm = max(equityratio_22), by(firm_id)
	
foreach var in eq_19_firm eq_22_firm{
	replace `var' = . if `var' < 0 | `var' > 100 //dropping outliers
}	
gen high_eq = (eq_19_firm > r(p50)) if eq_19_firm != .

*cash to assets
egen cash_20_firm = max(cor9_cash1), by(firm_id)
gen high_cash = (cash_20_firm > r(p50)) if cash_20_firm != .

*export share
egen rev_abroad_firm = max(rev_abroad), by(firm_id)

*firm age
replace found = . if found == 0 | found < 1000
egen found_firm =  max(found), by(firm_id)

gen age = year - found_firm
*gen age_2023_12 = age if date_m == ym(2023,12)
gen ln_age = ln(age)

gen ln_age_w = ln_age
forval t = 2012/2025{
*sum ln_age if year == `t',d 
replace ln_age_w = r(p1) if ln_age < r(p1) & year == `t'
replace ln_age_w = r(p99) if ln_age > r(p99) & ln_age != . & year == `t'
}
sum age if date_m == ym(2024, 12),d //prior: 2023
gen old_firm = (age > r(p25)) if age != .

* business exp
gen comexp_s = ""
replace comexp_s = "better" if comexp >= 0.5 & comexp != . 
replace comexp_s = "same" if comexp < 0.5 & comexp > -.5
replace comexp_s = "worse" if comexp <= -0.5 
encode comexp_s, gen(comexp_f)

gen comexp_c = 1 if comexp_s == "better"
replace comexp_c = 0 if comexp_s == "same"
replace comexp_c = -1 if comexp_s == "worse"
gen comexp_good = (comexp_c == 1) if comexp_c != .

* business state
gen statebus_s = ""
replace statebus_s = "good" if statebus >= 0.5 & statebus != . 
replace statebus_s = "medium" if statebus < 0.5 & statebus > -.5
replace statebus_s = "bad" if statebus <= -0.5 
encode statebus_s, gen(statebus_f)

gen statebus_c = 1 if statebus_s == "good"
replace statebus_c = 0 if statebus_s == "medium"
replace statebus_c = -1 if statebus_s == "bad"
gen statebus_good = (statebus_c == 1) if statebus_c != .

* avg business state
areg statebus_c, absorb(date_m)
predict statebus_res, resid

egen statebus_m = mean(statebus_res) if date_m < ym(2025, 12) & date_m > ym(2023, 10) , by(firm_id) //prior: 2023, 2021
egen statebus_sd = sd(statebus_res) if date_m < ym(2025, 12) & date_m > ym(2023, 10) , by(firm_id) //prior: 2023, 2021

gen high_statbus_m = (statebus_m > r(p50)) if statebus_m != .

* avg business expectations
areg comexp_c, absorb(date_m)
predict comexp_res, resid

* average expectations
egen comexp_m = mean(comexp_res) if date_m < ym(2025, 12) & date_m > ym(2023, 10) , by(firm_id) //prior: 2023, 2021
egen comexp_sd = sd(comexp_res) if date_m < ym(2025, 12) & date_m > ym(2023, 10) , by(firm_id) //prior: 2023, 2021
sum comexp_m,d
gen high_comexp_m = (comexp_m > r(p50)) if comexp_m != .


* credit negotiations 
gen bank_restr = 0 if credit2_1 != . 
replace bank_restr = 1 if credit2_2 == 3
label var bank_restr "Bank acted restrictive"

replace credit2_1 = (credit2_1 - 2) * (-1)
label var credit2_1 "Loan negotiations"

*Have each row each of its years got quarterly values for credit2_1, bank_restr
	foreach q of numlist 1/4{
		local m = `q' * 3
		bysort firm_id year: egen bank_restr_q`q' = max(cond(month==`m', bank_restr, .))
		bysort firm_id year: egen credit2_1_q`q' = max(cond(month==`m', credit2_1, .))

}

* financing conditions relevant for investment next year
replace invfac_nj_fin = . if invfac_nj_fin == 1
replace invfac_nj_fin = 1 if invfac_nj_fin == 100
label var invfac_nj_fin "Financing conditions relevant next year"

replace invfac_dj_fin = . if invfac_dj_fin == 1
replace invfac_dj_fin = 1 if invfac_dj_fin == 100
label var invfac_dj_fin "Financing conditions relevant this year"


*inv goals next year
gen replacements_nj = invgoals_nj_repl // only replacements next year
replace replacements_nj = 0 if invgoals_nj_repl > 1 & replacements_nj != .

gen replacements_dj = invgoals_dj_repl // only replacements this year
replace replacements_dj = 0 if invgoals_dj_repl > 1 & replacements_dj != .

gen capacity_nj = invgoals_nj_cap // some capacity increases next year
replace capacity_nj = 1 if invgoals_nj_cap > 1 & invgoals_nj_cap !=  .

gen capacity_dj = invgoals_dj_cap // some capacity increases this year
replace capacity_dj = 1 if invgoals_dj_cap > 1 & invgoals_dj_cap !=  .

* average inv goals last 2 years
tsset firm_id date_m
gen l_replacements_dj = l12.replacements_dj
gen l2_replacements_dj = l24.replacements_dj
egen replacements_m = mean(replacements_dj) if  date_m <= ym(2025, 11) & date_m >= ym(2023, 11), by(firm_id)  //prior: 2023, 2021
replace replacements_m = .  if l_replacements_dj ==. | l2_replacements_dj == . | replacements_dj == .

gen l_capacity_dj = l12.capacity_dj
gen l2_capacity_dj = l24.capacity_dj
egen capacity_m = mean(capacity_dj) if  date_m <= ym(2025, 11) & date_m >= ym(2023, 11), by(firm_id) //prior: 2023, 2021
replace capacity_m = .  if l_capacity_dj ==. | l2_capacity_dj == . | capacity_dj == .



*Inv goals / Inv Factors lags
tsset firm_id date_m
foreach v in invgoals_nj_cap invgoals_nj_rat invgoals_nj_repl invgoals_nj_other invgoals_nj_no invfac_nj_dem invfac_nj_fin invfac_nj_tec invfac_nj_other invfac_nj_no invfac_dj_tax invfac_nj_tax {
	capture drop `v'_lagged
	gen `v'_lagged = l12.`v' if month == 11
}


*Build goal and factor revisions
local nyvars "invgoals_nj_cap_lagged invgoals_nj_rat_lagged invgoals_nj_repl_lagged invgoals_nj_other_lagged invgoals_nj_no_lagged invfac_nj_dem_lagged invfac_nj_fin_lagged invfac_nj_tec_lagged invfac_nj_other_lagged invfac_nj_no_lagged invfac_dj_tax_lagged invfac_nj_tax_lagged"
local lyvars "invgoals_dj_cap invgoals_dj_rat invgoals_dj_repl invgoals_dj_other invgoals_dj_no invfac_dj_dem invfac_dj_fin invfac_dj_tec invfac_dj_other invfac_dj_no"
local outvars "rev_invgoals_cap rev_invgoals_rat rev_invgoals_repl rev_invgoals_other rev_invgoals_no rev_invfac_dem rev_invfac_fin rev_invfac_tec rev_invfac_other rev_invfac_no"
local n: word count `lyvars'
forvalues i = 1/`n'{
	local ly : word `i' of `lyvars'
	local ny : word `i' of `nyvars'
	local out : word `i' of `outvars'
	
	capture drop `out'
	gen byte `out' = ///
	(cond(missing(`ly'), 0 , `ly'>0)) - ///
	(cond(missing(`ny'), 0 , `ny'>0)) ///
	if month == 11 & !(missing(`ly') & missing(`ny'))
}


*Tax Activated: Check firms who got treated in their taxing investment factors
gen byte tax_activation = (invfac_nj_tax_lagged == 0 & invfac_dj_tax == 100) if month == 11 & !missing(invfac_nj_tax_lagged) & !missing(invfac_dj_tax)


*Rechtsform: ~60% of firms in the subsample cannot be matched to their firm type, thus omit non- corporations 2, 3, and 4 in munis with <=400 Hebesatz
tab rechtsform if month == 11 & inrange(year, 2024, 2025), missing
count if missing(rechtsform) & inrange(year, 2024, 2025) & month == 11

capture drop lbt_curr
gen lbt_curr = lbt
replace lbt_curr = lbt_nov_lagged + lbt_change if missing(lbt_curr) & year == 2025 // zero-filled 2025 PLZs: current rate = last year's

capture drop below400
gen byte below400 = (lbt_curr <= 400) if !missing(lbt_curr)

capture drop shielded
gen byte shielded = .
replace shielded = 1 if inrange(rechtsform, 2, 4) & inrange(year, 2024, 2025) & month == 11
label var shielded "Hike bites: non-corporation above 400, only excluded ones from which we definitely know it"



*Investment splitting for construction and equipment revisions
tab date_m if !missing(invcon_nj) 

preserve
	keep if month == 11
	keep firm_id year inveq_nj invcon_nj
	replace year = year + 1
	rename inveq_nj inveq_nj_lagged
	rename invcon_nj invcon_nj_lagged
	tempfile eqconlag
	save `eqconlag'
restore
merge m:1 firm_id year using `eqconlag', keep(1 3) nogen

foreach v of varlist inveq_dj inveq_nj_lagged invcon_dj invcon_nj_lagged{
	clonevar `v'_r = `v'
	recode `v'_r (1=1) (2=0) (3=-1)
	label var `v'_r "`v' recoded (1 higher, 0 same, -1 lower)"
}
gen rev_inveq = inveq_dj_r - inveq_nj_lagged_r 
gen rev_invcon = invcon_dj_r - invcon_nj_lagged_r

foreach s in eq con {
	gen inv`s'_rev_down = (rev_inv`s' < 0) if !missing(rev_inv`s')
	gen inv`s'_rev_up = (rev_inv`s' > 0) if !missing(rev_inv`s')
}
sum rev_invcon




*Lagged treatment for Falsification Tests
preserve
	keep if month == 11
	keep plz_kgs year hike cut lbt_change
	replace year = year + 1
	rename (hike cut lbt_change) (hike_lag cut_lag lbt_change_lag) //Lag Version
	duplicates drop plz_kgs year, force
	tempfile lbtlagg
	save `lbtlagg'
restore
merge m:1 plz_kgs year using `lbtlagg', keep(1 3) nogen

preserve
	keep if month == 11
	keep plz_kgs year hike cut lbt_change
	replace year = year - 1
	rename (hike cut lbt_change) (hike_lead cut_lead lbt_change_lead) //Lead Version
	duplicates drop plz_kgs year, force
	tempfile lbtlead
	save `lbtlead'
restore
merge m:1 plz_kgs year using `lbtlead', keep(1 3) nogen

save "${final_data_dir}\IBS_Firm_Level_merged.dta", replace
********