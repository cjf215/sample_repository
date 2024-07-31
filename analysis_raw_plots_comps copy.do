********************************************************************************
//Project: Adult Reconnect
//Author: Coral Flanagan
//Date: 2023-09-01
//Purpose: Analysis for EEPA Submission
********************************************************************************

capture log close		
set more off            
clear all               
macro drop _all        

set scheme cleanplots, perm 

//Set Working Directory 
cd "/Users/coralflanagan1/Desktop/projects/adult_reconnect/scripts"

//Set Data Directory 

global ddir "../data/raw/"
global adir "../data/cleaned/"
global gdir "../graphics/"
global gtype png
global ttype rtf
set scheme s1color

//est putdocx 
putdocx clear 
putdocx begin
putdocx save ${gdir}plots, replace

//set globals
global covars_geo c_pop_tot c_pop_abv25_perc c_pop_abv25_as_perc c_pop_abv25_bk_perc c_pop_abv25_hsp_perc c_pop_abv25_wh_perc saipe_c_pov saipe_c_inc bls_unemploy st_pop_tot st_pop_abv25_perc st_pop_abv25_as_perc st_pop_abv25_bk_perc st_pop_abv25_hsp_perc st_pop_abv25_wh_perc med_inc_fred fred_unemploy_rate saipe_st_pov

global covars_inst tuition2 sfr academic_support_ppe inst_ppe student_services_ppe 

********************************************************************************
//Run Plots 
********************************************************************************

local levels bach assoc cert

foreach level of local levels{
use ${adir}clean_IPEDS.dta, clear

//drop out other years
drop if year<2012

//clean var name 
rename log_dg_over25_allcert log_dg_over25_cert 
	
if "`level'"=="bach"{
keep if iclevel==1
}
if "`level'"=="assoc"|"`level'"=="cert"{
keep if iclevel==0
}


//FL
preserve 

drop if elg_any==1 & stabbr!="FL"
g year_c=year-2013
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4


collapse log_dg_over25_`level', by(year_c elg_`level')

twoway (scatter log_dg_over25_`level' year_c if elg_`level'==1, ///
	mcolor(black%70) connect(direct) lcolor(black%70)) ///
	   (scatter log_dg_over25_`level' year_c if elg_`level'==0, ///
	   mcolor(black%30) connect(direct) lcolor(black%30)), ///
	   	title("FL", size(medium)) ///
		ytitle("") ///
		ylabel(,labsize(*0.5)) ///
	   legend(off) ///
		xtitle("Year",size(small))  ///
		xline(0, lcolor(black%40))


quietly graph save ${gdir}scatter_FL_`level'.gph, replace 
quietly graph export ${gdir}scatter_FL_`level'.$gtype, replace

restore

//IN
preserve 

drop if elg_any==1 & stabbr!="IN"
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

collapse log_dg_over25_`level', by(year_c elg_`level')

twoway (scatter log_dg_over25_`level' year_c if elg_`level'==1, ///
	mcolor(black%70) connect(direct) lcolor(black%70)) ///
	   (scatter log_dg_over25_`level' year_c if elg_`level'==0, ///
	   mcolor(black%30) connect(direct) lcolor(black%30)), ///
	   	title("IN", size(medium)) ///
		ytitle("") ///
		ylabel(,labsize(*0.5)) ///
	   legend(off) ///
		xtitle("Year",size(small))  ///
		xline(0, lcolor(black%40))

quietly graph save ${gdir}scatter_IN_`level'.gph, replace 
quietly graph export ${gdir}scatter_IN_`level'.$gtype, replace

restore

//MS
preserve 

drop if elg_any==1 & stabbr!="MS"
g year_c=year-2016
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4

collapse log_dg_over25_`level', by(year_c elg_`level')

twoway (scatter log_dg_over25_`level' year_c if elg_`level'==1, ///
	mcolor(black%70) connect(direct) lcolor(black%70)) ///
	   (scatter log_dg_over25_`level' year_c if elg_`level'==0, ///
	   mcolor(black%30) connect(direct) lcolor(black%30)), ///
	   	title("MS ", size(medium)) ///
		ytitle("") ///
		ylabel(,labsize(*0.5)) ///
		legend(off) ///
		xtitle("Year",size(small))  ///
		xline(0, lcolor(black%40))

quietly graph save ${gdir}scatter_MS_`level'.gph, replace 
quietly graph export ${gdir}scatter_MS_`level'.$gtype, replace

restore

//ID
preserve 

drop if elg_any==1 & stabbr!="ID"
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4


collapse log_dg_over25_`level', by(year_c elg_`level')

twoway (scatter log_dg_over25_`level' year_c if elg_`level'==1, ///
	mcolor(black%70) connect(direct) lcolor(black%70)) ///
	   (scatter log_dg_over25_`level' year_c if elg_`level'==0, ///
	   mcolor(black%30) connect(direct) lcolor(black%30)), ///
	   	title("ID ", size(medium)) ///
		ytitle("") ///
	    ylabel(,labsize(*0.5)) ///
		legend(off) ///
		xtitle("Year",size(small))  ///
		xline(0, lcolor(black%40))

quietly graph save ${gdir}scatter_ID_`level'.gph, replace 
quietly graph export ${gdir}scatter_ID_`level'.$gtype, replace

restore

//MN
preserve 
drop if elg_any==1 & stabbr!="MN"
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4


collapse log_dg_over25_`level', by(year_c elg_`level')

twoway (scatter log_dg_over25_`level' year_c if elg_`level'==1, ///
	mcolor(black%70) connect(direct) lcolor(black%70)) ///
	   (scatter log_dg_over25_`level' year_c if elg_`level'==0, ///
	   mcolor(black%30) connect(direct) lcolor(black%30)), ///
	   	title("MN", size(medium)) ///
		ytitle("") ///
		ylabel(,labsize(*0.5)) ///
		legend(off) ///
		xtitle("Year",size(small))  ///
		xline(0, lcolor(black%40))

quietly graph save ${gdir}scatter_MN_`level'.gph, replace 
quietly graph export ${gdir}scatter_MN_`level'.$gtype, replace

restore

//MD
preserve 

drop if elg_any==1 & stabbr!="MD"
g year_c=year-2018
g post=(year_c>=0)
keep if year_c>=-4 & year_c<=4


collapse log_dg_over25_`level', by(year_c elg_`level')

twoway (scatter log_dg_over25_`level' year_c if elg_`level'==1, ///
	mcolor(black%70) connect(direct) lcolor(black%70)) ///
	   (scatter log_dg_over25_`level' year_c if elg_`level'==0, ///
	   mcolor(black%30) connect(direct) lcolor(black%30)), ///
	   	title("MD", size(medium)) ///
		ytitle("") ///
		ylabel(,labsize(*0.5)) ///
		legend(off) ///
		xtitle("Year",size(small))  ///
		xline(0, lcolor(black%40))
quietly graph save ${gdir}scatter_MD_`level'.gph, replace 
quietly graph export ${gdir}scatter_MD_`level'.$gtype, replace

restore

}


********************************************************************************
//Combine plots 
********************************************************************************

local types ug 

foreach myvar of local types{
	
*bach

graph combine ${gdir}scatter_FL_bach.gph ///
${gdir}scatter_ID_bach.gph ///
${gdir}scatter_IN_bach.gph ///
${gdir}scatter_MD_bach.gph ///
${gdir}scatter_MS_bach.gph, ///
ycommon 

quietly graph save ${gdir}scatter_combined_bach_comps.gph, replace 
quietly graph export ${gdir}scatter_combined_bach_comps.$gtype, replace

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Bach"), bold font(Times,16) 
putdocx image ${gdir}scatter_combined_bach_comps.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}plots, append

*assoc
graph combine ${gdir}scatter_ID_assoc.gph ///
${gdir}scatter_IN_assoc.gph ///
${gdir}scatter_MD_assoc.gph ///
${gdir}scatter_MN_assoc.gph ///
${gdir}scatter_MS_assoc.gph, ///
ycommon

quietly graph save ${gdir}scatter_combined_assoc_comps.gph, replace 
quietly graph export ${gdir}scatter_combined_assoc_comps.$gtype, replace

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Assoc"), bold font(Times,16) 
putdocx image ${gdir}scatter_combined_assoc_comps.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}plots, append


*cert 
graph combine ${gdir}scatter_ID_cert.gph ///
${gdir}scatter_IN_cert.gph ///
${gdir}scatter_MN_cert.gph, ///
ycommon 

quietly graph save ${gdir}scatter_combined_cert_comps.gph, replace 
quietly graph export ${gdir}scatter_combined_cert_comps.$gtype, replace

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Cert"), bold font(Times,16) 
putdocx image ${gdir}scatter_combined_cert_comps.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}plots, append

}

exit




