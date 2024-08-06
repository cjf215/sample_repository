//think about adding to the match: school size, teacher recommendations, student course interest, parental course expectations 

********************************************************************************
//Project: Practicum Project
//Author: Coral Flanagan 
//Date: 2022-04-12
//Purpose: Analysis for Brent's Final Paper 
********************************************************************************
capture log close		// Clear logs
set more off            // Disable partitioned output
clear all               // Start with a clean slate
macro drop _all         // clear all macros
set graphics on 

set scheme cleanplots, perm 
estimates clear

//set data directory
global ddir "../data/raw/"
global adir "../data/cleaned/"
global gdir "../graphics/"
global gtype png
global ttype rtf
set scheme s1color

cd "/Users/coralflanagan1/Desktop/projects/prac_project_updated/scripts"

//load data
use ${adir}practicum_clean_imputed2.dta, clear
//mi set mlong
//mi extract 2

//gen new vars
g apib_stem=0
replace apib_stem=1 if apib_sc==1 | apib_math==1
replace apib_stem=. if apib_sc==. & apib_math==.

label var apib_stem  "Probability of Earning at least 1 Credit AP/IB Math or Science"

label var adv_hum "Probability of Earning at least 1 Credit AP/IB English or SS"

drop pc

gen pc=1
replace pc=0 if race==1
replace pc=. if race==. 

g enrl_4yr=.
replace enrl_4yr=1 if enrl_college3==2
replace enrl_4yr=0 if enrl_college3==1

drop math_score_std

egen math_score_std=std(math_score)


//establish putdoc
putdocx clear
putdocx begin
putdocx save ${gdir}analysis, replace

//set globals

*descriptives
global descriptives1 female ses i.race iep hgst_prnt_ed_col p1_employ math_score_std stu_edu_expect_c ///
p_edu_expect_c math_self_efficacy i.college_sure i.lang_mom i.lang_friends repeat_grade apib_math ///
apib_sc apib_eng apib_ss adv_any_cred 

global descriptives2 female ses i.race math_score_std i.lang_mom i.lang_friends enrl_any_college 

*analysis 1
global course_dem_covars female ses i.race iep hgst_prnt_ed_col fam_struc_c p1_employ  

global course_ach_covars math_score stu_edu_expect_m p_edu_expect_m math_self_efficacy i.college_sure i.lang_mom i.lang_friends repeat_grade

*analysis 2
global enrl_covars_dem ses female i.race math_score math_self_efficacy hgst_prnt_ed_col i.lang_mom i.lang_friends repeat_grade

global enrl_covars_col stu_edu_expect_m p_edu_expect_m    ///
college_study college_afford college_talking college_friend_plans i.college_sure college_working  ///
r_m_college r_m_college_success r_sc_college r_sc_college_success

//set globals margins
sum ses if ell==1, detail
global ses_ell=r(mean)

sum math_score if ell==1, detail
global math_score_ell=r(mean)

sum math_self_efficacy if ell==1, detail
global math_self_efficacy_ell=r(mean)

drop if race==.
drop if ell==.

exit



********************************************************************************
//Descriptive Statistics 
********************************************************************************

**Gen Table ELs and NEs in the Sample 
********************************************************************************
estimates clear 
eststo NE: mi estimate, post: mean $descriptives1 if ell==0
eststo EL: mi estimate, post: mean $descriptives1 if ell==1

estimates table NE EL, b(%10.2f) stats(N) varlabel allbaselevels

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Characteristics of ELs and NEs in the Sample"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx table tbl1(3,.), drop 

putdocx save ${gdir}analysis, append


**Gen Table ELs and NEs in the Sample 
********************************************************************************
estimates clear 
preserve 
drop if enrl_any_college==.

eststo NE: mi estimate, post: mean $descriptives2 if ell==0
eststo EL: mi estimate, post: mean $descriptives2 if ell==1

estimates table NE EL, b(%10.2f) stats(N) varlabel allbaselevels

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Characteristics of ELs and NEs in the Sample"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx table tbl1(3,.), drop 

putdocx save ${gdir}analysis, append

restore

exit



********************************************************************************
**RQ 1: Demonstrate that ELs in the sample have less course access 
********************************************************************************

//likelihood of taking course 
********************************************************************************
global outcomes apib_math apib_sc apib_eng apib_ss adv_any_cred 

foreach myvar of global outcomes{ 

eststo model1: mi estimate, post: reg `myvar' ell 
eststo model2: mi estimate, post: reg `myvar' ell $course_dem_covars
eststo model3: mi estimate, post: reg `myvar' ell $course_dem_covars $course_ach_covars 

estimates table model1 model2 model3, b(%10.2f) se(%10.2f) stats(N) ///
keep(ell) 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("RQ1: Likelihood of Taking `myvar'"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis, append

}





//Number of Credits 
********************************************************************************

global outcomes adv_total_math adv_total_sc adv_total_eng adv_total_ss adv_total

foreach myvar of global outcomes{ 

eststo model1: mi estimate, post: reg `myvar' ell 
eststo model2: mi estimate, post: reg `myvar' ell $course_dem_covars
eststo model3: mi estimate, post: reg `myvar' ell $course_dem_covars $course_ach_covars

estimates table model1 model2 model3, b(%10.2f) se(%10.2f) stats(N) ///
keep(ell ) 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("RQ1: Total Credits `myvar'"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis, append

}





//Margins Plots 
********************************************************************************

global outcomes apib_stem

foreach myvar of global outcomes{ 

mi estimate, post: reg `myvar' i.ell $course_covars
margins i.ell, at(race=5 female=0 math_score=$math_score_ell ///
stu_edu_expect_m=3 p_edu_expect_m=3 ib_test=4 ap_test=3 ///
plan_apib_sc=2 plan_apib_calc=2 hgst_prnt_ed_col=0)

}


********************************************************************************
//Matching and Generating Weights 
********************************************************************************

global ach_covars i.race math_score math_self_efficacy science_self_efficacy repeat_grade i.stu_edu_expect_m i.p_edu_expect_m ses female hgst_prnt_ed_col iep fam_struc_c p1_employ s_par_pay_college p1_race_pc p2_race_pc p_discuss_college lang_mom lang_friends t_math_treat_stu math_interest_std sc_interest_std r_math_enjoy r_sc_enjoy r_sc_parent r_m_college r_m_college_success r_sc_college r_sc_college_success college_study college_afford college_talking college_friend_plans college_sure college_working ap_test ib_test plan_apib_sc plan_apib_calc 

global sch_covars sch_climate coun_caseload col_coun sch_public coun_fin_aid cp_m_ptest_c cp_m_sched_c cp_m_stu_pref_c cp_m_trec_c  cp_s_grades_c cp_s_ptest_c cp_s_sched_c cp_s_stu_pref_c cp_s_trec_c fill_math_vac i.sch_resources coun_hrs_college_m t_sc_treat_stu t_math_treat_stu enrollment attendance12 highered_perc

global race_covars i.pc#c.ses i.pc#i.cp_m_ptest_c i.pc#i.cp_m_sched_c i.pc#i.cp_m_ptest_c i.pc#cp_m_sched_c i.pc# i.cp_m_stu_pref_c i.pc#i.cp_m_trec_c i.pc#i.female i.pc#c.math_self_efficacy i.pc#i.ell i.pc#c.math_score i.pc#i.hgst_prnt_ed_col i.pc#i.stu_edu_expect_m i.pc#i.p_edu_expect_m 

global ses_covars c.ses#c.ses c.ses#i.female c.ses#c.math_self_efficacy c.ses#i.ell c.ses#c.math_score c.ses#i.hgst_prnt_ed_col c.ses#i.stu_edu_expect_m c.ses#i.p_edu_expect_m

global mathscore_covars i.race#c.math_score c.math_score#c.math_score c.math_self_efficacy#c.math_score c.science_self_efficacy#c.math_score i.repeat_grade#c.math_score i.stu_edu_expect_m#c.math_score c.ses#c.math_score 

//Step One: Predict the Probability of Treatment 
********************************************************************************
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Step 1: Predict Probability"), bold font(Times,12)
putdocx save ${gdir}analysis, append 

local treatments apib_stem adv_hum adv_any_cred  

foreach myvar of local treatments {
	
	/*
	g p_score_`myvar'_el=.

	mi xeq 1/5: logit `myvar' $ach_covars $sch_covars $race_covars $mathscore_covars i.sch_region if ell==0
	predict p_score_`myvar'_`i'_ne, pr
	
	mi xeq 1/5: logit `myvar' $ach_covars $sch_covars $race_covars $ses_covars $math_score_covars i.sch_region if ell==1
	predict p_score_`myvar'_`i'_el1, pr
	
	replace p_score_`myvar'_el=p_score_`myvar'_`i'_el1 if ell==1
	replace p_score_`myvar'_el=p_score_`myvar'_`i'_ne if ell==0*/
	
	
	mi xeq 1/5: logit `myvar' $ach_covars $sch_covars $race_covars $mathscore_covars i.ell i.sch_region 
	predict p_score_`myvar', pr
	
	
	qui hist p_score_`myvar' if `myvar'==1, color(blue%70)  ///
	addplot(hist p_score_`myvar' if `myvar'==0, color(orange%30)) ///
	xtitle("Probability of `: variable label `myvar''") ///
	legend(order(1 "Coursetaker" 2 "Non-Coursetaker"))
	
	graph export ${gdir}hist.$gtype, replace
	graph save ${gdir}hist.gph, replace
	
	putdocx begin
	putdocx paragraph, halign(center)
	putdocx image ${gdir}hist.$gtype, width(5.78) height(4.2)
	putdocx save ${gdir}analysis, append
	
}



//Step Two: Generate IPTW weights 
********************************************************************************

*Stabilized
local treatments adv_any_cred apib_stem adv_hum 

foreach myvar of local treatments {
	
sum p_score_`myvar',detail 
scalar p_score_`myvar'_mean=r(mean)

gen ipw_weight_`myvar'_s=0
replace ipw_weight_`myvar'_s=1 if `myvar'==1 //ATT
replace ipw_weight_`myvar'_s=p_score_`myvar'_mean/(1-p_score_`myvar') if `myvar'==0

} 

save ${ddir}practicum_clean_weights, replace 


//Step Three: Check for Balance 
********************************************************************************
putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Step 3:  Match"), bold font(Times,12)
putdocx save ${gdir}analysis, append 

//NOTE, extracting one dataset here, need to change in the future

use ${ddir}practicum_clean_weights, clear
preserve
mi set mlong
mi extract 1

local treatments adv_any_cred apib_stem adv_hum 

foreach myvar of local treatments {

teffects ipw (enrl_any_college) (`myvar' $ach_covars $sch_covars $race_covars $ses_covars $mathscore_covars, logit), atet
tebalance summarize

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("Treatment: `myvar': Covariate Balance"), bold font(Times,12) 
putdocx table tbl1 = matrix(r(table)), rownames colnames 
putdocx table tbl1(.,.), nfor(%10.3f)
putdocx save ${gdir}analysis, append

tebalance density p_score_`myvar'

graph export ${gdir}balance1.$gtype, replace
graph save ${gdir}balance1.gph, replace
 
putdocx begin
putdocx paragraph, halign(center)
putdocx image ${gdir}balance1.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis, append

/*
tebalance density math_score 

graph export ${gdir}balance2.$gtype, replace
graph save ${gdir}balance2.gph, replace
 
putdocx begin
putdocx paragraph, halign(center)
putdocx image ${gdir}balance2.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis, append

tebalance density ses  

graph export ${gdir}balance3.$gtype, replace
graph save ${gdir}balance3.gph, replace
 
putdocx begin
putdocx paragraph, halign(center)
putdocx image ${gdir}balance3.$gtype, width(5.78) height(4.2)
putdocx save ${gdir}analysis, append
*/

}

*/


********************************************************************************
//Calculating Results 
********************************************************************************
*untrimmed

use ${ddir}practicum_clean_weights, replace 

local outcomes apib_stem adv_hum adv_any_cred 

foreach myvar of local outcomes {
	
eststo model1: mi estimate, post: reg enrl_any_college `myvar'##ell [pweight=ipw_weight_`myvar'_s], robust  
eststo model2: mi estimate, post: reg enrl_any_college `myvar'##ell $enrl_covars_dem [pweight=ipw_weight_`myvar'_s], robust 
eststo model3: mi estimate, post: reg enrl_any_college `myvar'##ell $enrl_covars_dem $enrl_covars_col [pweight=ipw_weight_`myvar'_s], robust 

estimates table model1 model2 model3, b(%10.2f) se(%10.2f) stats(N) ///
keep(1.`myvar' 1.`myvar'#1.ell) 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("RQ2: `myvar'-Untrimmed"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis, append
}
exit

*re-run trimmed

use ${ddir}practicum_clean_weights, replace 
mi set mlong
mi extract 2

local outcomes apib_stem adv_hum adv_any_cred 

foreach myvar of local outcomes {
drop if p_score_`myvar'>0.9 & `myvar'==0
eststo model1: reg enrl_any_college `myvar'##ell [pweight=ipw_weight_`myvar'_s], robust   
eststo model2: reg enrl_any_college `myvar'##ell $enrl_covars_dem [pweight=ipw_weight_`myvar'_s], robust   
eststo model3: reg enrl_any_college `myvar'##ell $enrl_covars_dem $enrl_covars_col [pweight=ipw_weight_`myvar'_s], robust
estimates table model1 model2 model3, b(%10.2f) se(%10.2f) stats(N) ///
keep(1.`myvar' 1.`myvar'#1.ell) 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("RQ2: `myvar'-Trimmed"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis, append

}


//4yr analysis
use ${ddir}practicum_clean_weights, replace 

preserve

drop if enrl_college3==0|enrl_college3==.

*untrimmed

local outcomes apib_stem adv_hum adv_any_cred 

foreach myvar of local outcomes {
	
eststo model1: mi estimate, post: reg enrl_4yr `myvar'##ell [pweight=ipw_weight_`myvar'_s], robust  
eststo model2: mi estimate, post: reg enrl_4yr `myvar'##ell $enrl_covars_dem [pweight=ipw_weight_`myvar'_s], robust
eststo model3: mi estimate, post: reg enrl_4yr `myvar'##ell $enrl_covars_dem $enrl_covars_col [pweight=ipw_weight_`myvar'_s],robust

estimates table model1 model2 model3, b(%10.2f) se(%10.2f) stats(N) ///
keep(1.`myvar' 1.`myvar'#1.ell) 

putdocx begin
putdocx paragraph, halign(center)
putdocx text ("RQ2: `myvar'-Untrimmed-4yr"), bold font(Times,12) 
putdocx table tbl1 = etable
putdocx save ${gdir}analysis, append
}

restore 

********************************************************************************
//Bounding Analysis 
*******************************************************************************

use ${ddir}practicum_clean_weights, replace 
mi set mlong
mi extract 1

local outcomes adv_any_cred

// adv_hum

foreach myvar of local outcomes {
preserve
drop if p_score_`myvar'>0.9 & `myvar'==0
reg enrl_any_college `myvar'##ell $enrl_covars_dem $enrl_covars_col [pweight=ipw_weight_`myvar'_s], robust
global r2_max=1.3*e(r2)
psacalc delta 1.`myvar'#1.ell
psacalc delta 1.`myvar'#1.ell, rmax($r2_max)
restore
}

exit


use ${ddir}practicum_clean_weights, replace
mi set mlong 
mi extract 1
 
local outcomes adv_any_cred

foreach myvar of local outcomes{
	drop if p_score_`myvar'==.
	sum p_score_`myvar' if `myvar'==0
	global p_score_max=r(max)
	sum p_score_`myvar' if `myvar'==1
	
	count if  p_score_`myvar'>$p_score_max & `myvar'==1

	
}






