/*******************************************************************************
* Merge Do-File
Also checks merging diagnostics
*******************************************************************************/

*Renaming Variables inside "hebesaetze" for Merge
use "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023", clear
ren ags plz_kgs
ren kreis kreisnr
save "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023temp.dta", replace


use ${final_data_dir}\IBS_Firm_Level, clear


*MERGE with 2003-2023 file
merge m:1 plz_kgs year using "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023temp"
ren _merge merged
save "${final_data_dir}\IBS_Firm_Level_merged.dta", replace

*Merge Diagnostics
tab year if merged == 2

preserve
keep if merged == 1
merge m:m plz_kgs using "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023temp", nogen
tab merged
restore

		*Any plz_kgs missing/mismatched?
	preserve
	keep plz_kgs
	duplicates drop
	save "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\temp", replace
	restore
	use "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023temp", clear
	keep plz_kgs
	duplicates drop
	merge 1:1 plz_kgs using "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\temp", keep(2) nogen
	di r(N) " plz_kgs in Master and not in hebesaetze!"
	erase "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\temp.dta"


	preserve
	keep plz_kgs
	duplicates drop
	save "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\temp", replace
	restore
	use "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023temp", clear
	keep plz_kgs
	duplicates drop
	merge 1:1 plz_kgs using "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\temp", keep(1) nogen
	di r(N) " plz_kgs in hebesatze and not in Master!"
	erase "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\temp.dta"


*Clean up Merge 2003-2023
use ${final_data_dir}\IBS_Firm_Level_merged, clear
drop if merged == 2 //CHECK!
drop merged
save "${final_data_dir}\IBS_Firm_Level_merged.dta", replace
erase "${ext_data_dir}\ebdc_import\muni_data_hebesaetze_2003_2023\muni_data_hebesaetze_2003_2023temp.dta"






*MERGE 2024 data
*Comvert to .dta
import excel using "${ext_data_dir}\71231-01-03-5.xlsx", cellrange(A3) firstrow clear
drop in 1/2
drop in 1
ren JahrGemeinden DG
ren B gemeindename
drop if missing(gemeindename) | strtrim(gemeindename)==""
gen year = 2024
destring year, replace
tostring DG, replace

capture drop _row
gen long _row = _n
sum _row if strtrim(gemeindename) == "Saarland", meanonly
gen byte before_saar = _row < r(min)
drop _row

*for pre plz "10....." bc of the weird formatting in the survey data
replace DG = substr(DG, 2, .) if before_saar == 1 & substr(DG, 1, 1)=="0"
replace DG = substr(DG + "000000", 1, 7) if before_saar == 1
*for post plz "10....."
replace DG = substr(DG + "0000000", 1, 8) if before_saar == 0


*gen len = length(DG)
*replace DG = DG + "000000" if len<8
*replace DG = substr(DG, 1, 7) if len<8
*drop len
*replace DG = substr(DG, 2, .) if length(DG) == 8 & substr(DG, 1, 1) == "0"
 

destring DG, gen(ags_merge)
ren ags_merge plz_kgs
*replace DG = DG + substr("00000000", 1, 8 - strlen(DG)) //making the dg mergable with "plz_kgs" in master

duplicates list plz_kgs

foreach v of varlist _all {
	if "`v'" == "year" | "`v'" == "plz_kgs" | "`v'" == "gemeindename" continue
	cap replace `v' = "" if `v' == "-"
	cap destring `v', replace
}
save "${ext_data_dir}/71231-01-03-5.dta", replace



*merge into "...merged.dta"
use ${final_data_dir}\IBS_Firm_Level_merged, clear
recast double plz_kgs
cap drop plz_str

merge m:1 plz_kgs year using "${ext_data_dir}/71231-01-03-5.dta"
drop if _merge == 2
drop _merge
save "${final_data_dir}\IBS_Firm_Level_merged.dta", replace


*Merge Check:
gen lbt = busitaxm
replace lbt = GewerbesteuerHebesatz if year == 2024

keep DG plz_kgs firm_id _merge year lbt month date_m busitaxm GewerbesteuerHebesatz gemeinde kreis 
drop if !inlist(year, 2024, 2023)

tabstat lbt, by (year) stat (mean median)

drop if !((year == 2023 & month == 12) | (year == 2024 & month == 1))
tabstat lbt, by (year) stat (mean median)

bysort firm_id (year month): gen lbt_change=lbt - lbt[_n-1]
sum lbt_change, detail

tabstat lbt if !missing(lbt_change), by(year) stat(mean median p25 p75 p99)
tabstat lbt if _merge==3, by(year) stat(mean median p25 p75 p99)

bysort year month: gen n_firms = _N
tab year month

preserve 
keep if _merge==3
keep firm_id
duplicates drop
save matched_firms, replace
restore

merge m:1 firm_id using matched_firms, keep(3) nogen
tabstat lbt, by(year) stat(mean median p25 p75 p99)


bysort firm_id: egen ever_matched = max(_merge==3)
keep if ever_matched
tabstat lbt, by(year) stat(mean median p25 p75 p99)
tabstat lbt_change if _merge==3, by(year) stat(mean median p25 p75 p99)


count if !missing(lbt_change)
count if !missing(lbt) & year == 2023 & month == 12
count if !missing(lbt) & year == 2024 & month == 1

bysort firm_id: egen has_jan= max(year == 2024 & month == 1 & !missing(lbt))
tabstat lbt if year == 2023 & month == 12, by(has_jan) stat(mean median n)

tabstat lbt if has_jan == 1, by(year) stat(mean median p25)


erase matched_firms.dta









*MERGE 2025 data
*Comvert to .dta
import delimited using "${ext_data_dir}\71231-02-01-5.csv", clear
drop in 1/7
drop v1 v4 v5 v6
ren v7 gemeindehebesatz 
ren v3 nome
ren v2 DG
drop if missing(nome) | strtrim(nome)==""
gen year = 2025
destring year, replace

gen ags_merge = DG
tostring ags_merge, replace
ren ags_merge plz_kgs
*replace DG = DG + substr("00000000", 1, 8 - strlen(DG)) //making the dg mergable with "plz_kgs" in master

foreach v of varlist _all {
	if "`v'" == "year" | "`v'" == "plzkgs" | "`v'" == "nome" continue
	cap replace `v' = "" if `v' == "-"
	cap destring `v', replace
}
save "${ext_data_dir}/71231-02-01-5.dta", replace


*merge into "...merged.dta"
use ${final_data_dir}\IBS_Firm_Level_merged, clear
recast double plz_kgs
cap drop plz_str

merge m:1 plz_kgs year using "${ext_data_dir}/71231-02-01-5.dta"


save "${final_data_dir}\IBS_Firm_Level_merged.dta", replace









*Merge the VG borrcaps:
use "${data_dir}\ebdc\KTVG_2026-01_neu", clear

keep if inlist(year, 2023, 2024, 2025)
ren sector_wz08 sector_wz08111

duplicates report idnum year month survey runnum
duplicates tag idnum year month survey runnum, gen(dup)
list idnum year month survey runnum if dup > 0, sepby(idnum year month survey runnum) 
drop if dup > 0 & missing(online)

keep idnum month year survey runnum       sector_wz08111 vg_prestatebus_unc sector_id vg_perc_borrcap vg_perc_borrcap_ny
tostring survey, replace
replace survey = "IND" if survey == "vg" & !missing(survey) //!!!!!!!!!!!!!!!!!!!!!!!!!!

save "${data_dir}/KTVG_2026-01_lean.dta", replace

use ${final_data_dir}\IBS_Firm_Level_merged, clear

merge m:1 idnum year month using "${data_dir}/KTVG_2026-01_lean.dta"





destring sector_wz08111, replace
count if _merge == 1 & sector_wz08111 == sector_wz08 
count if _merge == 1 & inlist(year, 2023, 2024, 2025) & month == 11 & !missing(vg_perc_borrcap_ny)

count if _merge == 3 & year== 2023 & month==11 & !missing(vg_perc_borrcap_ny)
count if _merge == 2 & !missing(vg_perc_borrcap)

count if manu == 1 & year== 2023 & month==11 & !missing(borrcap_ny)
count if manu == 1 & year== 2023 & month==11 & !missing(vg_perc_borrcap_ny)

keep if manu == 1 & inlist(year, 2023, 2024, 2025) & month == 11

count if !missing(vg_perc_borrcap) & manu == 1 & inlist(year, 2023, 2024, 2025) &  month == 11
count if !missing(vg_perc_borrcap_ny)  & manu == 1 & inlist(year, 2023, 2024, 2025) &  month == 11



drop if _merge == 2
drop _merge


save "${final_data_dir}\IBS_Firm_Level_merged.dta", replace



****************