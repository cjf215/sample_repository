********************************************************************************
//Project: Adult Reconnect
//Title: Ipeds
//Author: Adela Soliz, Coral Flanagan
//Date: 2023-03-16
//Purpose: Analysis

/*NOTE: Comparison group for this file is only never implementers 
(expect for combined TWFE models)*/
********************************************************************************

capture log close		
set more off            
clear all               
macro drop _all        

**#
set scheme cleanplots, perm 

//Set Working Directory 
cd "/Users/coralflanagan1/Desktop/projects/adult_reconnect/scripts" //change working directory to scripts

//Set Data Directory 

global ddir "../data/raw/"
global adir "../data/cleaned/"
global gdir "../graphics/"
global gtype png
global ttype rtf
set scheme s1color

//load data
use ${adir}clean_IPEDS.dta, clear
exit


//create putdoc 
putdocx clear
putdocx begin
putdocx save ${gdir}analysis_updated, replace

//set globals
global covars_geo c_pop_tot c_pop_abv25_perc c_pop_abv25_as_perc c_pop_abv25_bk_perc c_pop_abv25_hsp_perc c_pop_abv25_wh_perc saipe_c_pov saipe_c_inc bls_unemploy st_pop_tot st_pop_abv25_perc st_pop_abv25_as_perc st_pop_abv25_bk_perc st_pop_abv25_hsp_perc st_pop_abv25_wh_perc med_inc_fred fred_unemploy_rate saipe_st_pov  

global covars_inst tuition2 sfr academic_support_ppe inst_ppe student_services_ppe 

global covars_inst_02 iclevel_02 tuition2_02 sfr_02 academic_support_ppe_02 inst_ppe_02 student_services_ppe_02 

//limit yrs
drop if year==1998
exit


********************************************************************************
/*Descriptive Tables */ 
********************************************************************************
 
drop if c_ug_over25==. //drop out missing outcome institutions that will be excluded from analysis 

***institution count overtime

tabulate year, matcell(cell) matrow(row)
matrix tab=(row,cell)
matrix colname tab= "Year" "Number of Institutions"

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Counts of Institutions By Year")
putdocx table oneway=matrix(tab), colnames 
putdocx save ${gdir}analysis_updated, append

tabulate year if elg_any==1, matcell(cell) matrow(row)
matrix tab=(row,cell)
matrix colname tab= "Year" "Number of Treated Institutions"

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Counts of Institutions By Year")
putdocx table oneway=matrix(tab), colnames 
putdocx save ${gdir}analysis_updated, append

tabulate year if elg_any==0, matcell(cell) matrow(row)
matrix tab=(row,cell)
matrix colname tab= "Year" "Number of Control Institutions"

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Counts of Institutions By Year")
putdocx table oneway=matrix(tab), colnames 
putdocx save ${gdir}analysis_updated, append

***descriptive stats 
global years 2002 //add more years here if needed 

foreach myvar of global years {

*state and county characteristics 
eststo treated: mean $covars_geo if year==`myvar' & elg_any==1
eststo comparison: mean $covars_geo if year==`myvar' & elg_any==0 //never implementers
estimates table treated comparison, b(%10.2f) stats(N) varlabel 



putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Table 1: Descriptive Statistics, State and County Characteristics, Year `myvar'"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis_updated, append
exit

*4-year institutions

preserve 
keep if iclevel==1

eststo treated: mean c_ug_total c_ug_over25 perc_c_ug_over25 $covars_inst  if year==`myvar' & elg_bach==1
eststo comparison: mean c_ug_total c_ug_over25 perc_c_ug_over25 $covars_inst c_ug_total c_ug_over25 perc_c_ug_over25 if year==`myvar' & elg_any==0 
estimates table treated comparison, b(%10.2f) stats(N) varlabel 

eputdocx begin
putdocx paragraph, halign(center)
putdocx text ("Table 2: Descriptive Statistics, Institution Characteristics, Bach-Eligible, 4-year Institutions, Year `myvar'"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis_updated, append

restore

*2-year institutions-assoc

preserve 
keep if iclevel==0

eststo treated: mean  c_ug_total c_ug_over25 perc_c_ug_over25  $covars_inst if year==`myvar' & elg_assoc==1
eststo comparison: mean c_ug_total c_ug_over25 perc_c_ug_over25  $covars_inst  if year==`myvar' & elg_any==0 
estimates table treated comparison, b(%10.2f) stats(N) varlabel 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Table 3, Descriptive Statistics, Institution Characteristics, 2-Year Institutions, Assoc-Eligible, Year `myvar'"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis_updated, append

restore 

*2-year institutions-cert

preserve 
keep if iclevel==0

eststo treated: mean c_ug_total c_ug_over25 perc_c_ug_over25 $covars_inst  if year==`myvar' & elg_cert==1
eststo comparison: mean c_ug_total c_ug_over25 perc_c_ug_over25 $covars_inst  if year==`myvar' & elg_any==0 
estimates table treated  comparison, b(%10.2f) stats(N) varlabel 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Table 4, Descriptive Statistics, Institution Characteristics, 2-Year Institutions, Cert-Eligible Year `myvar'"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis_updated, append

restore 


}


exit

********************************************************************************
/*Event Studies by Wave*/ 
********************************************************************************


//eligible for both 2 and 4 year 
local waves wv_all wv_03 wv_05 wv_10 wv_16 wv_18 

foreach myvar of local waves{
use ${adir}clean_IPEDS.dta, clear	
keep if `myvar'==1 | comp_group==1

replace timetoevent=. if elg_bach==0

*4yr
preserve
keep if iclevel==1
drop if elg_bach==0 & elg_any==1

eventdd log_c_ug_over25 i.year i.unitid, timevar(timetoevent) inrange lags(3) leads(4)
		
		graph export ${gdir}eventstudy.$gtype, replace
		graph save ${gdir}eventstudy.gph, replace
		
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Event Study-4yr Bach, `: variable label `myvar''"), bold font(Times,16)
putdocx image ${gdir}eventstudy.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis_updated, append

restore

*2yr-assoc 
preserve
keep if iclevel==0
drop if elg_any==1 & elg_assoc==0


eventdd log_c_ug_over25 i.year i.unitid, timevar(timetoevent) inrange lags(3) leads(4)
		
		graph export ${gdir}eventstudy.$gtype, replace
		graph save ${gdir}eventstudy.gph, replace
		
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Event Study-2yr Assoc, `: variable label `myvar''"), bold font(Times,16)
putdocx image ${gdir}eventstudy.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis_updated, append

restore

*2yr-cert  
preserve
keep if iclevel==0
drop if elg_any==1 & elg_cert==0


eventdd log_c_ug_over25 i.year i.unitid, timevar(timetoevent) inrange lags(3) leads(4)
		
		graph export ${gdir}eventstudy.$gtype, replace
		graph save ${gdir}eventstudy.gph, replace
		
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Event Study-2yr Cert, `: variable label `myvar''"), bold font(Times,16)
putdocx image ${gdir}eventstudy.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis_updated, append

restore

}

//eligible for only four year 
local waves wv_08 wv_13

foreach myvar of local waves{
use ${adir}clean_IPEDS.dta, clear	
keep if `myvar'==1 | comp_group==1

*4yr
preserve
keep if iclevel==1

eventdd log_c_ug_over25 i.year i.unitid, timevar(timetoevent) inrange lags(3) leads(4)
		
		graph export ${gdir}eventstudy.$gtype, replace
		graph save ${gdir}eventstudy.gph, replace
		
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Event Study-4yr, `: variable label `myvar''"), bold font(Times,16)
putdocx image ${gdir}eventstudy.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis_updated, append

restore


}



********************************************************************************
/*ENROLLMENT Impact Analysis*/ 
********************************************************************************

********************************************************************************
//All Waves Combined
********************************************************************************
*comparison group never treated and not-yet treated 

use ${adir}clean_IPEDS.dta, clear	
replace implementation_yr=0 if implementation_yr==.

*4-Year Institutions 
********************************************************************************

preserve

keep if iclevel==1
gen postXelg_any=(year>=implementation_yr & elg_bach==1)
drop if elg_bach==0 & elg_any==1 //should be 3, 4-years that only elg for assoc
label var postXelg_any "Adult-Targeted Scholarship for Bachelors"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)

estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_all.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Two-Way Fixed Effects") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) replace

//San'tanna 
csdid log_c_ug_over25 , ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_all.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')
 

restore


*2-Year Institutions 
********************************************************************************

//treated is eligible for Associates Degree
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_assoc==1)
drop if elg_cert==1 & elg_assoc!=1 //should be none
label var postXelg_any "Adult-Targeted Scholarship for Associates'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_all.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_all.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

//treated is eligble for Certificate 
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_cert==1)
drop if elg_assoc==1 & elg_cert!=1 //should drop 28 
label var postXelg_any "Adult-Targeted Scholarship for Certificate'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_all.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size


esttab matrix(temp) using ${gdir}analysis_all.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')

restore



********************************************************************************
//All Waves Combined w/out Ivy Tech 
********************************************************************************
*comparison group never treated and not-yet treated  

use ${adir}clean_IPEDS.dta, clear
drop if unitid==150987 //drop ivy tech
replace implementation_yr=0 if implementation_yr==.


*2-Year Institutions 
********************************************************************************
//treated is eligible for Associates Degree
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_assoc==1)
drop if elg_cert==1 & elg_assoc!=1 //should be none
label var postXelg_any "Adult-Targeted Scholarship for Associates'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_no_ivy_tech.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_no_ivy_tech.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

//treated is eligble for Certificate 
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_cert==1)
drop if elg_assoc==1 & elg_cert!=1 //should drop 28 
label var postXelg_any "Adult-Targeted Scholarship for Certificate'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_no_ivy_tech.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_no_ivy_tech.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

********************************************************************************
//All Waves Combined w/out LA 
********************************************************************************
*comparison group never treated and not-yet treated  

use ${adir}clean_IPEDS.dta, clear
drop if stabbr=="LA" 
replace implementation_yr=0 if implementation_yr==.

*4-Year Institutions 
********************************************************************************

preserve

keep if iclevel==1
gen postXelg_any=(year>=implementation_yr & elg_bach==1)
drop if elg_bach==0 & elg_any==1 //should be 3, 4-years that only elg for assoc
label var postXelg_any "Adult-Targeted Scholarship for Bachelors"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_no_LA.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Two-Way Fixed Effects") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) replace

//San'tanna 
csdid log_c_ug_over25 , ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_no_LA.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-sant'anna") keep(b se pvalue) append ///
stats(N `n')

restore

*2-Year Institutions 
********************************************************************************
//treated is eligible for Associates Degree
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_assoc==1)
drop if elg_cert==1 & elg_assoc!=1 //should be none
label var postXelg_any "Adult-Targeted Scholarship for Associates'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_no_LA.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_no_LA.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

//treated is eligble for Certificate 
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_cert==1)
drop if elg_assoc==1 & elg_cert!=1 //should drop 28 
label var postXelg_any "Adult-Targeted Scholarship for Certificate'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_no_LA.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_no_LA.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore


********************************************************************************
//All Waves Combined: Strong Implementers Only 
********************************************************************************
*comparison group never treated and not-yet treated 

use ${adir}clean_IPEDS.dta, clear
drop if elg_any==1 & elg_strong!=1 //drop out all the "weak" implementers
drop if stabbr=="LA" 
replace implementation_yr=0 if implementation_yr==.

*4-Year Institutions 
********************************************************************************

preserve

keep if iclevel==1
gen postXelg_any=(year>=implementation_yr & elg_strong==1)
drop if elg_bach==0 & elg_any==1 //should be 3, 4-years that only elg for assoc
label var postXelg_any "Adult-Targeted Scholarship for Bachelors"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)

estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_all_strong.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Two-Way Fixed Effects") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) replace


//San'tanna 
csdid log_c_ug_over25 , ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_all_strong.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

*2-Year Institutions 
********************************************************************************

//treated is eligible for Associates Degree
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_assoc_strong==1)
drop if elg_cert_strong==1 & elg_assoc_strong!=1 //should be none
label var postXelg_any "Adult-Targeted Scholarship for Associates'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_all_strong.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table)
local n= e(N) //sample size 

esttab matrix(temp) using ${gdir}analysis_all_strong.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

//treated is eligble for Certificate 
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_cert_strong==1)
drop if elg_assoc_strong==1 & elg_cert_strong!=1 //should drop 28 
label var postXelg_any "Adult-Targeted Scholarship for Certificate'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_all_strong.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append

//San'tanna 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size


esttab matrix(temp) using ${gdir}analysis_all_strong.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore




********************************************************************************
//Separately by Wave
********************************************************************************

local waves wv_03 wv_10 wv_16 wv_18 
//wv_05 (need to run this without cert only)

//wv_08 wv_13 
foreach myvar of local waves{
	
use ${adir}clean_IPEDS.dta, clear
keep if `myvar'==1 | comp_group==1
sum implementation_yr
scalar  t_implementation_yr=r(mean)
keep if year< t_implementation_yr+5 //4 pre and post periods 
keep if year> t_implementation_yr-5

*4-Year Institutions 
********************************************************************************

preserve

keep if iclevel==1
gen postXelg_any=(year>=implementation_yr & elg_bach==1)
drop if elg_bach==0 & elg_any==1 //should be 3, 4-years that only elg for assoc
label var postXelg_any "Adult-Targeted Scholarship for Bachelors"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)

estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_waves.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Two-Way Fixed Effects, `: variable label `myvar''") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna
replace implementation_yr=0 if implementation_yr==. 
csdid log_c_ug_over25 , ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_waves.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-sant'anna, `: variable label `myvar''") keep(b se pvalue) append ///
stats(N `n')
 

restore

*2-Year Institutions 
********************************************************************************

//treated is eligible for Associates Degree
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_assoc==1)
drop if elg_cert==1 & elg_assoc!=1 //should be none
label var postXelg_any "Adult-Targeted Scholarship for Associates'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_waves.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions, `: variable label `myvar''") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna 
replace implementation_yr=0 if implementation_yr==. 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_waves.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-sant'anna, `: variable label `myvar''") keep(b se pvalue) append ///
stats(N `n')


restore

//treated is eligble for Certificate 
preserve

keep if iclevel==0
gen postXelg_any=(year>=implementation_yr & elg_cert==1)
drop if elg_assoc==1 & elg_cert!=1 //should drop 28 
label var postXelg_any "Adult-Targeted Scholarship for Certificate'"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_waves.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions, `: variable label `myvar''") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append

//San'tanna 
replace implementation_yr=0 if implementation_yr==. 
csdid log_c_ug_over25, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size


esttab matrix(temp) using ${gdir}analysis_waves.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 2-Year Institutions-Sant'anna, `: variable label `myvar''") keep(b se pvalue) append ///
stats(N `n')


restore
	
}



//4-year eligible only
local waves wv_08 wv_13 
foreach myvar of local waves{
	
use ${adir}clean_IPEDS.dta, clear
keep if `myvar'==1 | comp_group==1
sum implementation_yr
scalar  t_implementation_yr=r(mean)
keep if year< t_implementation_yr+5 //4 pre and post periods 
keep if year> t_implementation_yr-5

*4-Year Institutions 
********************************************************************************

preserve

keep if iclevel==1
gen postXelg_any=(year>=implementation_yr & elg_bach==1)
drop if elg_bach==0 & elg_any==1 //should be 3, 4-years that only elg for assoc
label var postXelg_any "Adult-Targeted Scholarship for Bachelors"

xtset unitid year 

eststo model1: xtreg log_c_ug_over25  postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_c_ug_over25  postXelg_any i.year $covars_geo, fe i(unitid)

estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_waves.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-Two-Way Fixed Effects, `: variable label `myvar''") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna
replace implementation_yr=0 if implementation_yr==. 
csdid log_c_ug_over25 , ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size


esttab matrix(temp) using ${gdir}analysis_waves.rtf, title("Effect of Adult-Targeted Scholarship on Undergraduate Enrollment Over 25 in 4-Year Institutions-sant'anna, `: variable label `myvar''") keep(b se pvalue) append ///
stats(N `n')


restore

	
}


********************************************************************************
//COMPLETIONS
********************************************************************************

use ${adir}clean_IPEDS.dta, clear	
replace implementation_yr=0 if implementation_yr==.

*4-Year Institutions 
********************************************************************************
preserve 

drop if year<2012
drop if elg_any==1 & implementation_yr>2015 //get rid of implementers that we don't have time to see effects

gen postXelg_any=(year>=implementation_yr & elg_bach==1)
label var postXelg_any "Adult-Targeted Scholarship for Bachelors"

xtset unitid year 

eststo model1: xtreg log_dg_over25_bach postXelg_any i.year, fe i(unitid)
 
eststo model2: xtreg log_dg_over25_bach postXelg_any i.year $covars_geo, fe i(unitid)

estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_c_ug_over25  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_comps.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on number of Bachelor's Degrees Awarded to over 25s-Two-Way Fixed Effects") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) replace

//San'tanna 
csdid log_dg_over25_bach, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_comps.rtf, title("Effect of Adult-Targeted Scholarship on number of Bachelor's Degrees Awarded to over 25s-Two-Way Fixed Effects-sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

*2-Year Institutions 
********************************************************************************

//treated is eligible for Associates Degree
preserve

drop if year<2012
drop if elg_any==1 & implementation_yr>2017 //get rid of implementers that we don't have time to see effects

gen postXelg_any=(year>=implementation_yr & elg_assoc==1)
drop if elg_cert==1 & elg_assoc!=1 //should be none
label var postXelg_any "Adult-Targeted Scholarship for Associates'"

xtset unitid year 

eststo model1: xtreg log_dg_over25_assoc  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
eststo model2: xtreg log_dg_over25_assoc  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_dg_over25_assoc  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_comps.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on number of Associate's Degrees Awarded to over 25s in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append 

//San'tanna 
csdid log_dg_over25_assoc, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_comps.rtf, title("Effect of Adult-Targeted Scholarship on number of Associate's Degrees Awarded to over 25s -Sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore

//treated is eligble for Certificate 
preserve

drop if year<2012
drop if elg_any==1 & implementation_yr>2019 //get rid of implementers that we don't have time to see effects

gen postXelg_any=(year>=implementation_yr & elg_cert==1)
drop if elg_assoc==1 & elg_cert!=1 //should drop 28 
label var postXelg_any "Adult-Targeted Scholarship for Certificate'"

xtset unitid year 

eststo model1: xtreg log_dg_over25_allcert  postXelg_any i.year, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "No", replace 
estadd local inst_controls "No", replace
 
eststo model2: xtreg log_dg_over25_allcert  postXelg_any i.year $covars_geo, fe i(unitid)
estadd local fixed_effects "Yes", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "No", replace
   
eststo model3: xtreg log_dg_over25_allcert  postXelg_any i.year $covars_inst_02 $covars_geo
estadd local fixed_effects "No", replace 
estadd local st_ct_controls "Yes", replace 
estadd local inst_controls "Yes", replace  


esttab model* using ${gdir}analysis_comps.rtf, se(%10.3f) label title("Effect of Adult-Targeted Scholarship on number of Associate's Degrees Awarded Over 25 in 2-Year Institutions") nomtitle keep(postXelg_any) s(st_ct_controls fixed_effects inst_controls N, label("State/County Controls" "Institution Fixed Effects" "Institution Controls")) append

//San'tanna 
csdid log_dg_over25_allcert, ivar(unitid) time(year) gvar(implementation_yr) 

estat simple

mat temp=r(table) 
local n= e(N) //sample size

esttab matrix(temp) using ${gdir}analysis_comps.rtf, title("Effect of Adult-Targeted Scholarship on number of Associate's Degrees Awarded Over 25 in 2-Year Institutions-sant'anna") keep(b se pvalue) append ///
stats(N `n')


restore











