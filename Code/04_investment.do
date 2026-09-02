/*******************************************************************************
* 04 Investment Regression Do-File
*******************************************************************************/

*Yearly overview: do tax changes filter into investment revisions?
*Are Revisions in Investment Plans also predicted by LBT Hikes/Cuts 
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


keep if inrange(year, 2024, 2025) & month == 11

keep if anticipated !=1 // OMIT ANTICIPATED ONES

keep if shielded != 1  // OMIT SHIELDED ONES







reghdfe inv_rev_up hike if manu ==1 & rechtsform == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu !=1 & rechtsform == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe inv_rev_down hike if manu ==1 & rechtsform == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu !=1 & rechtsform == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc




* Panel regressions: rev_invest on hike
*keep if statebus == 0
reghdfe inv_rev_down hike, absorb(year)
hc
reghdfe inv_rev_down hike,vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike, absorb(year) vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut, absorb(year) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu !=1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu ==1 & inv_planned_stable == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu !=1 & inv_planned_stable == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe inv_rev_up hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu !=1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc


reghdfe inv_rev_up hike if inv_planned_stable == 1, absorb(year)
hc
reghdfe inv_rev_up hike if inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe inv_rev_up hike if inv_planned_stable == 1, absorb(year)
hc
reghdfe inv_rev_up hike if inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up hike cut if inv_planned_stable == 1, absorb(year) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if inv_planned_stable == 1 & manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if inv_planned_stable == 1 & manu !=1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc


*For Equipment or Construction

reghdfe invcon_rev_down hike if manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe invcon_rev_down hike if manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe inveq_rev_up hike if manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inveq_rev_up hike if manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe invcon_rev_down hike if manu != 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe invcon_rev_down hike if manu == 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe inveq_rev_up hike if manu != 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inveq_rev_up hike if manu == 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe invcon_rev_down lbt_change if manu != 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe invcon_rev_down lbt_change if manu == 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

reghdfe inveq_rev_up lbt_change if manu != 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inveq_rev_up lbt_change if manu == 1 & inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc

*New Point 25.6.: for inv_planned_stable: Look at quant. changes as in Link et al

use "${final_data_dir}\IBS_Firm_Level_merged.dta", clear

bysort firm_id year: egen althike = max(cond(month == 11, hike, .))
replace hike = althike if month != 11 & missing(hike) & !missing(althike) //Spread hikes on other months too
drop althike

bysort firm_id year: egen altlbt = max(cond(month == 11, lbt_change, .))
replace lbt_change = altlbt if month != 11 & missing(lbt_change) & !missing(altlbt) //Spread hikes on other months too
drop altlbt
*Manuels first measure: Binary Downward Revision of Investment assuming ly was realized (in conj. with inv_planned_stable). If restricted to borrcap measure only data from 2024
keep if month == 3 & year == 2024

*Quantitative investment overview
tabstat inv_quant_ly invchange_quant_ly ln_invchange_quant_ly_win, stat(n mean p10 p50 p90) columns(statistics)
tabstat inv_quant_ly invchange_quant_ly ln_invchange_quant_ly_win if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, stat(n mean p10 p50 p90) columns(statistics)

tabstat inv_quant_ly invchange_quant_ly ln_invchange_quant_ly_win if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & manu==1, stat(n mean p10 p50 p90) columns(statistics)
tabstat inv_quant_ly invchange_quant_ly ln_invchange_quant_ly_win if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & manu!=1, stat(n mean p10 p50 p90) columns(statistics)


reghdfe inv_down_quant hike, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if manu==1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if manu != 1, vce(cluster plz_kgs)
hc


reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu!=1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu==1, vce(cluster plz_kgs)
hc
*Most sensible Output

reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & manu!=1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1 & manu==1, vce(cluster plz_kgs)
hc

*if we separate the investment channel with inv_planned_stable:
reghdfe inv_down_quant hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu!=1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if inv_planned_stable == 1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu==1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if inv_planned_stable == 1 & manu!=1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant hike if inv_planned_stable == 1 & manu==1, vce(cluster plz_kgs)
hc


*For Appendix: sensibility to FE/clustering on down quant
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster bundesland)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu!=1, vce(cluster bundesland)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu==1, vce(cluster bundesland)
hc

reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu!=1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu==1, absorb(sector_wz08_2digit) vce(cluster bundesland)
hc

reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit) vce(cluster bundesland)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu!=1, absorb(sector_wz08_4digit) vce(cluster bundesland)
hc
reghdfe inv_down_quant hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu==1, absorb(sector_wz08_4digit) vce(cluster bundesland)
hc


	*with levels lbtchange
reghdfe inv_down_quant lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe inv_down_quant lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu!=1, vce(cluster plz_kgs)
hc
reghdfe inv_down_quant lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & manu==1, vce(cluster plz_kgs)
hc






////
*Manuels second: Log Revision Ratio
////
reghdfe ln_invchange_quant_ly_win hike, vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu != 1, vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu == 1, vce(cluster plz_kgs)
hc


reghdfe ln_invchange_quant_ly_win hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
*Most sensible Output

reghdfe ln_invchange_quant_ly_win hike if inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu!=1 & inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu==1 & inv_planned_stable == 1, vce(cluster plz_kgs)
hc

reghdfe ln_invchange_quant_ly_win hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged) & inv_planned_stable == 1, vce(cluster plz_kgs)
hc

//because the prior year's investment is used as a proxy, beta is attenuated towards zero in the log ratio because of noise around proxy. The binary downward indicator however might be comparable, as the constant 0.4 - 0.5 (4x% of firms revise downwards quantitatively) is close to the one in the paper at "slightly larger than 0.5".

*For Appendix: sensibility to FE/clustering on log revisions ratio
*not winsorized (almost the same)
reghdfe ln_invchange_quant_ly hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly hike if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly hike if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc

reghdfe ln_invchange_quant_ly_win hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster bundesland)
hc
reghdfe ln_invchange_quant_ly_win hike if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster bundesland)
hc
reghdfe ln_invchange_quant_ly_win hike if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster bundesland)
hc

reghdfe ln_invchange_quant_ly_win hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe ln_invchange_quant_ly_win hike if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit) vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit) vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win hike if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), absorb(sector_wz08_4digit) vce(cluster plz_kgs)
hc

	*levels again
reghdfe ln_invchange_quant_ly_win lbt_change if borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win lbt_change if manu!=1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc
reghdfe ln_invchange_quant_ly_win lbt_change if manu==1 & borrcap_ny_lagged != 0 & !missing(borrcap_ny_lagged), vce(cluster plz_kgs)
hc




use "${final_data_dir}\IBS_Firm_Level_merged.dta", clear


* Directional splits: inv_rev_down / inv_rev_up on hike
eststo clear
eststo down: reghdfe inv_rev_down hike if inv_planned_stable == 1, vce(cluster plz_kgs)
hc

eststo up: reghdfe inv_rev_up hike if inv_planned_stable == 1, vce(cluster plz_kgs)
hc

#delimit ;
esttab down up using "${output_dir}\Table_PanelRevInvestDirectional.tex",
    replace fragment booktabs nomtitles nonumbers noobs nonotes compress
    cells(b(star fmt(4)) se(par fmt(4)))
    star(* 0.10 ** 0.05 *** 0.01)
    keep(hike)
    coeflabels(hike "\texttt{hike}")
    stats(sectorfe cluster N r2,
        labels("Sector FE" "Cluster" "\(N\)" "\(R^2\)")
        fmt(0 0 0 3)
    )
    prehead(
        "\begin{table}[H]"
        "\centering"
        "\caption{Directional splits: downward vs upward investment revisions on hike}"
        "\begin{threeparttable}"
        "\small"
        "\begin{tabular}{lcc}"
        "\toprule"
        "                     & \texttt{inv\_rev\_down} & \texttt{inv\_rev\_up}   \\"
    )
    posthead("\midrule")
    prefoot("\midrule")
    postfoot(
        "\bottomrule"
        "\end{tabular}"
        "\end{threeparttable}"
        "\end{table}"
    );
#delimit cr



********************************************************************************
* Year-by-year investment revisions on hike
********************************************************************************
use "${final_data_dir}\IBS_Firm_Level_merged.dta", clear

*On Header rev_invest
eststo clear
forval y = 2016/2025 {
	eststo y`y': reghdfe rev_invest hike if year == `y' & inv_planned_stable==1, vce(cluster plz_kgs)
	hc
}
esttab y2016 y2017 y2018 y2019 y2020 y2021 y2022 y2023 y2024 y2025 using "${output_dir}\rev_invest_byyear.tex", b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) keep(hike) mtitles(2016 2017 2018 2019 2020 2021 2022 2023 2024 2025) replace

*Directional
eststo clear
eststo down_all: reghdfe inv_rev_down hike if inv_planned_stable==1, vce(cluster plz_kgs)
hc
eststo up_all: reghdfe inv_rev_up hike if inv_planned_stable==1, vce(cluster plz_kgs)
hc
forval y = 2016/2025 {
	eststo down`y': reghdfe inv_rev_down hike if year == `y' & inv_planned_stable==1,  vce(cluster plz_kgs)
	hc
	eststo up`y': reghdfe inv_rev_up hike if year == `y' & inv_planned_stable==1, vce(cluster plz_kgs)
	hc
}
esttab down_all up_all down2016 up2016 down2017 up2017 down2018 up2018 down2019 up2019 down2020 up2020 down2021 up2021 down2022 up2022 down2023 up2023 down2024 up2024 down2025 up2025 using "${output_dir}\rev_invest_directional.tex", b(3) se(3) star(* 0.1 ** 0.05 *** 0.01) keep(hike) mtitles("Down" "Up" "Down" "Up""Down" "Up" "Down" "Up" "Down" "Up" "Down" "Up" "Down" "Up" "Down" "Up" "Down" "Up" "Down" "Up" "Down" "Up") mgroups("Full" "" 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025, pattern(1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0)) replace


********************************************************************************
* Year-by-year investment revisions on hike split into Sectors (surveys)
********************************************************************************
*Pre-Covid
preserve
keep if inrange(year, 2016, 2019) & month == 11
reghdfe inv_rev_down hike cut if comm==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut if serv==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut if manu==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_up hike cut if manu==1,   vce(cluster plz_kgs)
hc

reghdfe inv_rev_down hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu !=1 , absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu !=1 , absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
restore

*Covid
preserve
keep if inrange(year, 2020, 2023) & month == 11
reghdfe inv_rev_down hike cut if comm==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut if serv==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut if manu==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_up hike cut if manu==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu !=1 , absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu !=1 , absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
restore

*years of interest 2024 & 2025
preserve
keep if inrange(year, 2024, 2025) & month == 11
reghdfe inv_rev_down hike cut if comm==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut if serv==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike cut if manu==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_up hike cut if manu==1,   vce(cluster plz_kgs)
hc
reghdfe inv_rev_down hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_down hike if manu !=1 , absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
reghdfe inv_rev_up hike if manu !=1 , absorb(year sector_wz08_2digit) vce(cluster plz_kgs) 
hc
restore




*More trials
reghdfe inv_rev_down i.hike##c.borrcap_ny_lagged, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_down i.hike##c.borrcap_ny_lagged if inv_planned_stable, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_down i.hike##c.borrcap_ny_lagged if manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_down i.hike##c.borrcap_ny_lagged if manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_down i.hike##c.borrcap_ny_lagged if inv_planned_stable & manu !=1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_down i.hike##c.borrcap_ny_lagged if inv_planned_stable & manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)

reghdfe inv_rev_up i.hike##c.borrcap_ny_lagged, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_up i.hike##c.borrcap_ny_lagged if inv_planned_stable, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_up i.hike##c.borrcap_ny_lagged if manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_up i.hike##c.borrcap_ny_lagged if manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_up i.hike##c.borrcap_ny_lagged if inv_planned_stable & manu !=1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
reghdfe inv_rev_up i.hike##c.borrcap_ny_lagged if inv_planned_stable & manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)






gen byte cap_goal = (invgoals_nj_cap_lagged > 0) if !missing(invgoals_nj_cap_lagged)

reghdfe inv_rev_down i.hike##i.cap_goal, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_down i.hike##i.cap_goal if inv_planned_stable, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up i.hike##i.cap_goal, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up i.hike##i.cap_goal if inv_planned_stable, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe inv_rev_down i.hike##i.cap_goal if manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_down i.hike##i.cap_goal if inv_planned_stable & manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up i.hike##i.cap_goal if manu == 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up i.hike##i.cap_goal if inv_planned_stable & manu ==1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc

reghdfe inv_rev_down i.hike##i.cap_goal if manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_down i.hike##i.cap_goal if inv_planned_stable & manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up i.hike##i.cap_goal if manu != 1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)
hc
reghdfe inv_rev_up i.hike##i.cap_goal if inv_planned_stable & manu !=1, absorb(year sector_wz08_2digit) vce(cluster plz_kgs)



****************