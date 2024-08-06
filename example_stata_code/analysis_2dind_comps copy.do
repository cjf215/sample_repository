********************************************************************************
//Project: Adult Reconnect
//Author: Coral Flanagan 
//Date: 2023-07-07
//Purpose: Event Study Plots 
********************************************************************************

capture log close		
set more off            
clear all               
macro drop _all        

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

//set globals
global covars_geo c_pop_tot c_pop_abv25_perc c_pop_abv25_as_perc c_pop_abv25_bk_perc c_pop_abv25_hsp_perc c_pop_abv25_wh_perc saipe_c_pov saipe_c_inc bls_unemploy st_pop_tot st_pop_abv25_perc st_pop_abv25_as_perc st_pop_abv25_bk_perc st_pop_abv25_hsp_perc st_pop_abv25_wh_perc med_inc_fred fred_unemploy_rate saipe_st_pov st_pop_total_as st_pop_total_bk st_pop_total_hsp st_pop_total_na st_pop_total_wh st_pop_tot c_pop_tot c_pop_total_as c_pop_total_bk c_pop_total_hsp c_pop_total_na c_pop_total_wh tuition2 sfr academic_support_ppe inst_ppe student_services_ppe c_inst_count  

g missing=0

foreach myvar of global covars_geo{
replace missing=1 if `myvar'==.

}


********************************************************************************
//Run Two Period Models 
********************************************************************************

********************************************************************************
//Comp Group All 
********************************************************************************

***bach 
//load data
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==1
drop if year<2012

//FL
preserve 
g year_c=year-2013
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="FL"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_all_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "FL:2013") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MS
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MS"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_all_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "MS:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_all_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_all_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MD
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MD"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_all_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "MD:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

***assoc 
//load data
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==0
drop if year<2012

//MS
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MS"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_assoc_cert.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MS:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_assoc_cert.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_assoc_cert.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MD
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MD"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_assoc_cert.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MD:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MN
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MN"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_assoc_cert.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

***cert 
//load data
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==0
drop if year<2012

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore


//MN
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MN"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_all_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

********************************************************************************
//non-implementers
********************************************************************************

***bach 
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==1
drop if year<2012


//FL
preserve 
g year_c=year-2013
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

keep if stabbr=="FL"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) 

esttab model1 model2 model3 using "${gdir}cg_nonimp_bach_comps.csv", replace /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "FL:2013") compress nonum varwidth(17) ///
unstack alignment(r) mtitles("(1)" "(2)" "(3)")

restore


***assoc
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==0
 
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

keep if stabbr=="MN"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid)

esttab model1 model2 model3 using "${gdir}cg_nonimp_assoc_comps.csv", replace /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) mtitles("(1)" "(2)" "(3)")

restore

***cert
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==0
 
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

keep if stabbr=="MN"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) 

esttab model1 model2 model3 using "${gdir}cg_nonimp_cert_comps.csv", replace /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) mtitles("(1)" "(2)" "(3)")

restore

********************************************************************************
//younger students 
********************************************************************************
***bach 
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==1
drop if year<2012

//FL
preserve 
g year_c=year-2013
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="FL"

xtset unitid 
eststo model1: reg log_dg_1824_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "FL:2013") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MS
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MS"

xtset unitid 
eststo model1: reg log_dg_1824_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "MS:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_1824_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_1824_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MD
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MD"

xtset unitid 
eststo model1: reg log_dg_1824_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "MD:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

***assoc 
//load data
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==0
drop if year<2012

//MS
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MS"

xtset unitid 
eststo model1: reg log_dg_1824_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MS:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_1824_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_1824_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MD
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MD"

xtset unitid 
eststo model1: reg log_dg_1824_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MD:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MN
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MN"

xtset unitid 
eststo model1: reg log_dg_1824_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

***cert 
//load data
use ${adir}clean_IPEDS.dta, clear
keep if iclevel==0
drop if year<2012

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_1824_allcert  i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_allcert  i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_allcert  i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_1824_allcert  i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_allcert  i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_allcert  i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore


//MN
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

drop if elg_any==1 & stabbr!="MN"

xtset unitid 
eststo model1: reg log_dg_1824_allcert  i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_1824_allcert  i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_1824_allcert  i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_younger_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//nearby states
********************************************************************************
***bach 
//load data
use ${adir}clean_IPEDS.dta, clear
drop comp_group
keep if iclevel==1
drop if year<2012

//FL
preserve 
g year_c=year-2013
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="GA"|stabbr=="AL")

keep if comp_group==1| stabbr=="FL"
drop if elg_any==1 & stabbr!="FL"
drop if stabbr=="FL" & elg_bach==0

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_neighbor_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "FL:2013") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MS
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="AL"|stabbr=="AK")

keep if comp_group==1| stabbr=="MS"
drop if elg_any==1 & stabbr!="MS"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_neighbor_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "MS:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="OH"|stabbr=="IL")

keep if comp_group==1| stabbr=="IN"
drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_neighbor_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="MT"|stabbr=="WY"|stabbr=="NV"|stabbr=="OR"|stabbr=="WA")

keep if comp_group==1| stabbr=="ID"
drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_neighbor_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MD
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="PA"|stabbr=="DE"|stabbr=="VA")

keep if comp_group==1| stabbr=="MD"
drop if elg_any==1 & stabbr!="MD"

xtset unitid 
eststo model1: reg log_dg_over25_bach i.elg_bach##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_bach i.elg_bach##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_bach i.elg_bach##i.post $covars_geo, fe i(unitid) vce(cluster stabbr) 
 

esttab model1 model2 model3  using  "${gdir}cg_neighbor_bach_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_bach#1.post) ///
coeflabel(1.elg_bach#1.post "MD:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

***assoc 
//load data
use ${adir}clean_IPEDS.dta, clear
drop comp_group
keep if iclevel==0
drop if year<2012

//MS
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="AL"|stabbr=="AK")

keep if comp_group==1| stabbr=="MS"
drop if elg_any==1 & stabbr!="MS"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MS:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="OH"|stabbr=="IL")

keep if comp_group==1| stabbr=="IN"
drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="MT"|stabbr=="WY"|stabbr=="NV"|stabbr=="OR"|stabbr=="WA")

keep if comp_group==1| stabbr=="ID"
drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MD
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="PA"|stabbr=="DE"|stabbr=="VA")

keep if comp_group==1| stabbr=="MD"
drop if elg_any==1 & stabbr!="MD"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MD:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//MN
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="WI"|stabbr=="SD"|stabbr=="ND")

keep if comp_group==1| stabbr=="MN"
drop if elg_any==1 & stabbr!="MN"
drop if elg_assoc==0 & stabbr=="MN"

xtset unitid 
eststo model1: reg log_dg_over25_assoc i.elg_assoc##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_assoc i.elg_assoc##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_assoc_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_assoc#1.post) ///
coeflabel(1.elg_assoc#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

***cert 
//load data
use ${adir}clean_IPEDS.dta, clear
drop comp_group
keep if iclevel==0
drop if year<2012

//IN
preserve 
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="OH"|stabbr=="IL")

keep if comp_group==1| stabbr=="IN"
drop if elg_any==1 & stabbr!="IN"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "IN:2016") compress nonum varwidth(17) ///
unstack alignment(r) 
restore

//ID
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="MT"|stabbr=="WY"|stabbr=="NV"|stabbr=="OR"|stabbr=="WA")

keep if comp_group==1| stabbr=="ID"
drop if elg_any==1 & stabbr!="ID"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nonotes nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "ID:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore


//MN
preserve 
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4
g comp_group=(stabbr=="WI"|stabbr=="SD"|stabbr=="ND")

keep if comp_group==1| stabbr=="MN"
drop if elg_any==1 & stabbr!="MN"
drop if elg_cert==0 & stabbr=="MN"

xtset unitid 
eststo model1: reg log_dg_over25_allcert i.elg_cert##i.post, vce(cluster stabbr)
eststo model2: reg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, vce(cluster stabbr)
eststo model3: xtreg log_dg_over25_allcert i.elg_cert##i.post $covars_geo, fe i(unitid) vce(cluster stabbr)

esttab model1 model2 model3  using  "${gdir}cg_neighbor_cert_comps.csv", append /// 
star(+ .10 * .05 ** .01 *** .001) se(3) b(3) noconstant nomtitles ///
keep(1.elg_cert#1.post) ///
coeflabel(1.elg_cert#1.post "MN:2018") compress nonum varwidth(17) ///
unstack alignment(r) 
restore










