/*******************************************************************************
* Master Do-File
* Project: [Firms' Investment and Borrowing Responses to Tax Hikes]
* Authors: [Paul]
* Date Created: April 4, 2024
* Last Modified: July 24, 2026
* EBDC Project Number: 
* Data Sources: 
*******************************************************************************/

/* Clear environment */
clear all
set more off
capture log close

/* Set directories */
global root_dir "F:\0947_Best_Menge" // TODO: enter name
global code_dir "$root_dir/code"
global env_dir "$root_dir/env"
global export_dir "$root_dir/export"
global data_dir "$root_dir/data"
global ebdc_data_dir "$data_dir/ebdc"
global ext_data_dir "$data_dir/ext"
global final_data_dir "$data_dir/final"
global log_dir "$root_dir/log"
global output_dir "$root_dir/output"
global documents_dir "$root_dir/documents"
global temp_dir "$root_dir/temp"

/* Create directories if they don't exist */
foreach dir in code_dir env_dir export_dir data_dir ebdc_data_dir ext_data_dir final_data_dir log_dir output_dir documents_dir temp_dir {
    capture mkdir "${`dir'}"
}

/* Set adopath */
adopath + "$env_dir/stata"

/* Start log */
log using "$log_dir/master_log_`c(current_date)'.log", replace

/*******************************************************************************
* 1. Data Preparation
*******************************************************************************/
 
do "$code_dir/01_merge.do"
do "$code_dir/02_var_prep.do"

/*******************************************************************************
* 2. Data Analysis
*******************************************************************************/

do "$code_dir/03_analysis.do"
do "$code_dir/04_investment.do"
do "$code_dir/05_borrowing.do"


/*******************************************************************************
* 3. Additional Analyses or Robustness Checks
*******************************************************************************/

do "$code_dir/06_Falsification&Robustness.do"




/* Close log */
log close

/* End of do-file */
