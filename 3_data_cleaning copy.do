********************************************************************************
//Project: Adult Reconnect
//Title: Ipeds
//Author: Adela Soliz, Coral Flanagan
//Date: 2022-04-12
//Purpose: Clean Data 
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

//load data
use ${adir}IPEDS_merged.dta, clear

********************************************************************************
//Limit sample 
********************************************************************************

//recode missing values in control and iclevel 
replace control=. if control==-3
replace iclevel=. if iclevel==-3

//drop out any random states/territories (limit to 50 states plus DC)
drop if stabbr=="FM"|stabbr=="GU"| stabbr=="MH"| stabbr=="MP"| stabbr=="VI"| stabbr=="PW"|stabbr=="PR"|stabbr=="AS"

//limit sample
drop if sector==0 | sector==99  //drop unknown sector and admin units
drop if control==3 //drop for-profits
keep if deggrant==1 //degree-granting only
keep if ugoffer==1 //offers undergrad degrees
keep if pset4flg==1 //postsec title iv

keep if control==1 //publics only 
*NOTE: Current Analysis is Limited to Publics Only

//recode iclevel so it is 0/1 (easier to work with)

replace iclevel=0 if iclevel==2

label define iclevel_labels1   	  	  1 "4-year" /// 
									  0 "2-year" 
label values iclevel iclevel_labels1

//drop CT
drop if stabbr=="CT"

*NOTE: I have been dropping CT from the analysis because they had an adult targeted scholarship for 1 year only


********************************************************************************
/*Clean Outcome Variables */
********************************************************************************


//QUESTION: Is it ok that zeros are now missing?


//create combined age variables for completion  
********************************************************************************

//fill in 0 for missing so I can compute sums 
foreach x of varlist dg_tot_assoc dg_under18_assoc dg_1824_assoc dg_2539_assoc dg_abv40_assoc dg_age_unkn_assoc dg_tot_bach ///
dg_under18_bach dg_1824_bach dg_2539_bach dg_abv40_bach dg_age_unkn_bach dg_tot_cert1 dg_under18_cert1 dg_1824_cert1 dg_2539_cert1 ///
dg_abv40_cert1 dg_age_unkn_cert1 dg_tot_cert12w dg_under18_cert12w dg_1824_cert12w dg_2539_cert12w dg_abv40_cert12w ///
dg_age_unkn_cert12w dg_tot_cert12wplus dg_under18_cert12wplus dg_1824_cert12wplus dg_2539_cert12wplus dg_abv40_cert12wplus ///
dg_age_unkn_cert12wplus dg_tot_cert1plus dg_under18_cert1plus dg_1824_cert1plus dg_abv40_cert1plus dg_2539_cert1plus dg_age_unkn_cert1plus {
  replace `x' = 0 if(`x' == .)
}

//gen over 25 combined enrollment
local dg assoc bach cert1 cert1plus cert12w cert12wplus 

foreach myvar of local dg {
gen dg_over25_`myvar'=0
replace dg_over25_`myvar'= dg_2539_`myvar'+dg_abv40_`myvar'
g log_dg_over25_`myvar'=log(dg_over25_`myvar')
replace log_dg_over25_`myvar'=0 if missing(log_dg_over25_`myvar') & year>=2012
}

local dg cert1 cert1plus cert12w cert12wplus 

foreach myvar of local dg {
replace dg_1824_`myvar'=0 if missing(dg_1824_`myvar')
	
}

g dg_1824_allcert=dg_1824_cert1 + dg_1824_cert12w + dg_1824_cert12wplus + dg_1824_cert1plus

g log_dg_1824_bach=log(dg_1824_bach)
g log_dg_1824_assoc=log(dg_1824_assoc)
g log_dg_1824_allcert=log(dg_1824_allcert)

local dg assoc bach allcert

foreach myvar of local dg {
replace log_dg_1824_`myvar'=9 if log_dg_1824_`myvar'==. & year>=2012
}


gen dg_over25_allcert= dg_over25_cert1 + dg_over25_cert1plus + dg_over25_cert12w + dg_over25_cert12wplus
g log_dg_over25_allcert=log(dg_over25_allcert)
gen dg_tot_allcert=dg_tot_cert1 + dg_tot_cert1plus + dg_tot_cert12w + dg_tot_cert12wplus

label var dg_over25_bach "Number of Bachelors Awarded to over 25s"
label var dg_over25_assoc "Number of Associates Awarded to over 25s"
label var dg_over25_allcert "Number of Certs Awarded to over 25s"
label var dg_over25_cert1 "Number of Certs 13-51 wks Awarded to over 25s"
label var dg_over25_cert1plus "Number of Certs 53-209 wks Awarded to over 25s"

label var log_dg_over25_bach "Logged Bachelors Awarded to over 25s"
label var log_dg_over25_assoc "Logged Associates Awarded to over 25s"
label var log_dg_over25_allcert "Logged Certs Awarded to over 25s"
label var log_dg_over25_cert1 "Logged Certs 13-51 wks Awarded to over 25s"
label var log_dg_over25_cert1plus "Logged Certs 53-209 wks Awarded to over 25s"




********************************************************************************
/*Clean Treatment Variables*/
********************************************************************************
gen elg_any=0 
gen elg_bach=0
gen elg_assoc=0
gen elg_cert=0
g elg_any_late=0

label var elg_any  "All Eligible Institutions"
label var elg_bach  "Bachelors' Eligible Institutions"
label var elg_assoc "Associates' Eligible Institutions"
label var elg_cert "Cert Eligible Institutions"
label var elg_any_late "Eligible Institutions (Post 2018 Implementation)"

egen ofr_bach=max(dg_tot_bach>0), by(unitid) //offer bach
egen ofr_assoc=max(dg_tot_assoc>0), by(unitid)
egen ofr_cert=max(dg_tot_allcert>0), by(unitid)

//NOTE: If a state does not list specific institutions that are eligible for a bachelors versus associates or cert but rather has a general list of institutions that are eligible for the program and the program applies to multiple degree types (ie you can get either a bachelors or an associates with this program), I code all eligible institutions are eligible for all degree types given that a 2-year colelge might have a few bachelors degree programs that would technically be eligible. However, future analysis is limited to either 2- or 4-year programs. 

//TN Hope
********************************************************************************
*Note: There is a list of eligible institutions (see below). Nearly every public institution is eligible. 

replace elg_any= 1 if unitid==219602|unitid==219639|unitid==219709|unitid==219718|unitid==219790|unitid==219806| /// 
unitid==219824|unitid==219833| unitid==219879|unitid==219888|unitid==219949|unitid==219976|unitid==220057|unitid==220075| ///
unitid==220181|unitid==220206|unitid==220215|unitid==220400|unitid==220464|unitid==220473|unitid==220516|unitid==220552| ///
unitid==220598|unitid==220604|unitid==220613|unitid==220631|unitid==220701|unitid==220710|unitid==220862|unitid==220978| ///
unitid==221096|unitid==221184|unitid==221351|unitid==221397|unitid==221485|unitid==221519|unitid==221643|unitid==221661| ///
unitid==221731|unitid==221740|unitid==221759|unitid==221768|unitid==221838|unitid==221847|unitid==221892|unitid==221908| ///
unitid==221953|unitid==221971|unitid==221999|unitid==222053|unitid==222062|unitid==486901|unitid==487010| unitid==221704| ///
unitid==221652

replace elg_bach=1 if elg_any==1 & stabbr=="TN"
replace elg_assoc=1 if elg_any==1 & stabbr=="TN"
replace elg_cert=0 if stabbr=="TN"



*certificate programs are not eligible 

/*
LIST OF ELIGIBLE INSTITUTIONS: 
*ETSU-School of Pharmacy is on eligile list but is not listed separately in IPEDS
*Knoxville College (private) is on eligible list but is not in ipeds
219602	Austin Peay State University	
219639	Baptist Health Sciences University	
219709	Belmont University	
219718	Bethel University	
219790	Bryan College-Dayton	
219806	Carson-Newman University	
219824	Chattanooga State Community College	
219833	Christian Brothers University	
219879	Cleveland State Community College	
219888	Columbia State Community College	
219949	Cumberland University	
219976	Lipscomb University	
220057	Dyersburg State Community College	
220075	East Tennessee State University	
220181	Fisk University	
220206	Welch College	
220215	Freed-Hardeman University	
220400	Jackson State Community College	
220464	John A Gupton College	
220473	Johnson University	
220516	King University	
220552	South College	
220598	Lane College	
220604	Le Moyne-Owen College	
220613	Lee University	
220631	Lincoln Memorial University	
220701	The University of Tennessee Southern	
220710	Maryville College	
220862	University of Memphis	
220978	Middle Tennessee State University	
221096	Motlow State Community College
221184	Nashville State Community College
221351	Rhodes College	
221397	Roane State Community College	
221485	Southwest Tennessee Community College	
221519	The University of the South	
221643	Pellissippi State Community College	
221661	Southern Adventist University	
221731	Tennessee Wesleyan University	
221740	The University of Tennessee-Chattanooga
221759	The University of Tennessee-Knoxville	
221768	The University of Tennessee-Martin	
221838	Tennessee State University	
221847	Tennessee Technological University	
221892	Trevecca Nazarene University	
221908	Northeast State Community College	
221953	Tusculum University
221971	Union University	
221999	Vanderbilt University	
222053	Volunteer State Community College	
222062	Walters State Community College
486901	Milligan University
487010	The University of Tennessee Health Science Center	
*/


//WV (note: the scholarship is for pt enrollment only) 
********************************************************************************
//Eligible Institutes: Per website: "Community colleges, state colleges or universities, an independent colleges or universities in West Virginia. To determine if an institution participates in the HEAPS Grant Program, please contact the institution's financial aid office."
//I am coding all non-profit institutions in WV as eligible


replace elg_any=1 if stabbr=="WV"
replace elg_bach=1 if stabbr=="WV"
replace elg_assoc=1 if stabbr=="WV"
replace elg_cert=1 if stabbr=="WV"




//ID
********************************************************************************
*Eligible Institutions: There is a list of eligible institutions (see below). This is all public institutions in ID. 

replace elg_any=1 if unitid==142115|unitid==142522|unitid==142294|unitid==142559|unitid==455114|unitid==142179|unitid==142276|unitid==142328|unitid==142443|unitid==142461|unitid==142285

replace elg_bach=1 if unitid==142115|unitid==142522|unitid==142294|unitid==142559|unitid==455114|unitid==142179|unitid==142276|unitid==142328|unitid==142443|unitid==142461|unitid==142285|unitid==433387 

replace elg_assoc=1 if unitid==142115|unitid==142522|unitid==142294|unitid==142559|unitid==455114|unitid==142179|unitid==142276|unitid==142328|unitid==142443|unitid==142461|unitid==142285|unitid==433387 

replace elg_cert=1 if unitid==142115|unitid==142522|unitid==142294|unitid==142559|unitid==455114|unitid==142179|unitid==142276|unitid==142328|unitid==142443|unitid==142461|unitid==142285|unitid==433387

//QUESTION: Western Governor's Univeristy is technically located UT but listed as eligible for this scholarship (unitid=433387). It is included for now. It is also eligible for the UT program so may not make a difference in combined analyses 

/*LIST OF ELIGIBLE INSTITUTIONS: 
Boise State University
Brigham Young University – Idaho
College of Idaho
College of Southern Idaho
College of Western Idaho
College of Eastern Idaho
Idaho State University
Lewis-Clark State College
North Idaho College
Northwest Nazarene University
University of Idaho
Western Governors University
*/



//IN
********************************************************************************
*Eligible Institutions: Per website: "Must be an Indiana resident and a U.S. Citizen or eligible non-citizen. Must be enrolled, or plan to enroll, in a course of study leading to an associate or first bachelor's degree, or a certificate at Ivy Tech Community College or Vincennes University"
*I have interpreted this as meaning you must be enrolled in a bachelor or associates degree program at any institution in IN, OR a certificate program only at Ivy Tech or Vincennes. 

replace elg_any=1 if stabbr=="IN"
replace elg_bach=1 if stabbr=="IN"
replace elg_assoc=1 if stabbr=="IN"
replace elg_cert=1 if unitid==152637 | unitid==150987 //ivy tech and vincennes are the ONLY cert eligible 

replace iclevel=0 if unitid==152637




//LA Go Grant
********************************************************************************
*Eligible institutions: "Louisiana public colleges or universities and regionally accredited independent colleges or universities in the state that are members of the Louisiana Association of Independent Colleges and Universities. OR Louisiana public colleges that have been granted regional candidacy status, but are not yet eligible to participate in title IV programs. Candidacy status institutions must require students to complete a FAFSA and the institution must determine a student's eligibility in accordance with rules under this Chapter" (NOTE: we are limiting sample to Title IV eligible so these would be excluded)
*Elgible programs: "a program of study that is designed to lead to a certificate or undergraduate degree."
*Since current analysis is limited to public, I am interpreting this as all public institutions in LA

replace elg_any=1 if stabbr=="LA"
replace elg_bach=1 if stabbr=="LA"
replace elg_assoc=1 if stabbr=="LA" 
replace elg_cert=1 if stabbr=="LA" 




//ME (NOTE: technically only applies for certs of at least 1 year)
********************************************************************************
*NOTE: all Title-IV eligible institutions in ME are eligible for this program
*Eligible program: "An eligible program of study is a degree or certificate/diploma program of at least one academic year in length offered by the institution, leading to a certificate, associate, or bachelor's degree."

replace elg_any_late=1 if stabbr=="ME"
/*
replace elg_bach=1 if stabbr=="ME" 
replace elg_assoc=1 if stabbr=="ME"
replace elg_cert=1 if stabbr=="ME" 
*/



//MI
********************************************************************************
*Eligible institutions are public community colleges ONLY
*Eligible programs are Associate or "Pell-eligible skill certificate" Only

replace elg_any_late=1 if stabbr=="MI" & iclevel==0 //do not remove, cc's only are eligible 
/*
replace elg_assoc=1 if stabbr=="MI" & iclevel==0
replace elg_cert=1 if stabbr=="MI"  & iclevel==0
*/




//MO
********************************************************************************
*There is a list of specific eligible programs at specific institutions.


replace elg_any_late=1 if unitid==179344|unitid==177551|unitid==177250|unitid==178387|unitid==179557|unitid==262031| ///
unitid==176965|unitid==177676|unitid==177995| unitid==179308|unitid==178420|unitid==178448|unitid==177977|unitid==179566| ///
unitid==179539|unitid==178341|unitid==178396|unitid==177472|unitid==177940|unitid==179715|unitid==179645|unitid==178624| ///
unitid==178411|unitid==178217|unitid==177135|unitid==178402|unitid==177551|unitid==178387|unitid==179557|unitid==179715| ///
unitid==179308|unitid==178420|unitid==179566| unitid==178341|unitid==178615|unitid==177940|unitid==178624|unitid==178411|unitid==178402|unitid==179344|unitid==177250|unitid==178387|unitid==179557|unitid==262031|unitid==177676| ///
unitid==177995|unitid==179308|unitid==178448|unitid==177977|unitid==179539|unitid==178341|unitid==177472| ///
unitid==177940|unitid==179715|unitid==179645|unitid==178217|unitid==177135

/*
replace elg_bach=1 if unitid==177551|unitid==178387|unitid==179557|unitid==179715|unitid==179308|unitid==178420|unitid==179566| ///
unitid==178341|unitid==178615|unitid==177940|unitid==178624|unitid==178411|unitid==178402

replace elg_assoc=1 if unitid==179344|unitid==177250|unitid==178387|unitid==179557|unitid==262031|unitid==177676| ///
unitid==177995|unitid==179308|unitid==178448|unitid==177977|unitid==179539|unitid==178341|unitid==177472| ///
unitid==177940|unitid==179715|unitid==179645|unitid==178217|unitid==177135

replace elg_cert=1 if unitid==179344|unitid==177551|unitid==177250|unitid==178387|unitid==179557|unitid==262031| ///
unitid==176965|unitid==177676|unitid==177995| unitid==179308|unitid==178420|unitid==178448|unitid==177977|unitid==179566| ///
unitid==179539|unitid==178341|unitid==178396|unitid==177472|unitid==177940|unitid==179715|unitid==179645|unitid==178624| ///
unitid==178411|unitid==178217|unitid==177135|unitid==178402
*/



/*LIST OF ELIGIBLE INSTITUTIONS
176965	University of Central Missouri	
177135	Crowder College
177250	East Central College	
177472	Ozarks Technical Community College	
177551	Harris-Stowe State University	
177676	Jefferson College	
177940	Lincoln University	
177977	State Technical College of Missouri	
177995	Metropolitan Community College-Kansas City	
178217	Mineral Area College	
178341	Missouri Southern State University	
178387	Missouri Western State University	
178396	University of Missouri-Columbia
178402	University of Missouri-Kansas City	
178411	Missouri University of Science and Technology	
178420	University of Missouri-St Louis	
178448	Moberly Area Community College	
178615	Truman State University	
178624	Northwest Missouri State University	
179308	Saint Louis Community College	
179344	Missouri State University-West Plains	
179539	State Fair Community College	
179557	Southeast Missouri State University	Cape 
179566	Missouri State University-Springfield	
179645	Three Rivers College	
179715	North Central Missouri College
262031	St Charles Community College	
*/

//MN
********************************************************************************
*See list of eligible institutions
*Eligible programs are "certificate, diploma or associate degree at the participating colleges"

replace elg_any=1 if unitid==173063|unitid==173461|unitid==173799|unitid==173911|unitid==173203|unitid==173416|unitid==174136| ///
unitid==174376| unitid==174570
replace elg_assoc=1 if unitid==173063|unitid==173461|unitid==173799|unitid==173911|unitid==173203|unitid==173416|unitid==174136| ///
unitid==174376| unitid==174570
replace elg_cert=1 if unitid==173063|unitid==173461|unitid==173799|unitid==173911|unitid==173203|unitid==173416|unitid==174136| ///
unitid==174376| unitid==174570

/*LIST OF ELIGIBLE INSTITUTIONS
South Central College*
Riverland Community College*
Central Lakes College+
Dakota County Technical College+
Inver Hills Community College*
Lake Superior College*
Minneapolis College+
North Hennepun Community College+
Pine Technical Community College+

*Joined in 2018
+Joined by 2020
(Program discontinued in 2021)
*/




//UT (NOTE: Online programs only)
********************************************************************************
*See list of eligible institutions 

replace elg_any_late=1 if unitid==230171|unitid==230603|unitid==230728|unitid==230746| unitid==230782| unitid==230807| unitid==433387 
/*
replace elg_assoc=1 if unitid==230171|unitid==230603|unitid==230728|unitid==230746| unitid==230782| unitid==230807| unitid==433387 
replace elg_bach=1 if unitid==230171|unitid==230603|unitid==230728|unitid==230746| unitid==230782| unitid==230807| unitid==433387 
replace elg_cert=1 if unitid==230171|unitid==230603|unitid==230728|unitid==230746| unitid==230782| unitid==230807| unitid==433387 
*/



/*LIST OF ELIGIBLE INSTITUTIONS:
Salt Lake Community College
Southern Utah University
Utah State University
Utah Tech University (formerly Dixie State)
Weber State University
Western Governors University
and Westminster College.
*/



//IA 
********************************************************************************
*Per website: "Eligible institutions are Iowa community colleges or accredited private colleges in Iowa that offer qualified programs of study and that agree to provide student services (including orientation and academic and career advising) and to facilitate the assignment of a volunteer mentor if a student requests one."
*There is a list of eligible colleges and programs on website, all are cert and associates 



replace elg_any_late=1 if unitid==152798|unitid==153214|unitid==153296|unitid==153311|unitid==153445|unitid==153472|unitid==153524| ///
unitid==153533	| unitid==153630|unitid==153737|unitid==153922|unitid==153977|unitid==154059|unitid==154110|unitid==154129| ///
unitid==154262|unitid==154378|unitid==154572|unitid==154396


/*ELIGIBLE INSTITUTIONS
152798	Allen College	
153214	Des Moines Area Community College	
153296	Ellsworth Community College	
153311	Eastern Iowa Community College District	
153445	Hawkeye Community College	
153472	Indian Hills Community College	
153524	Iowa Central Community College	
153533	Iowa Lakes Community College	
153630	Iowa Western Community College	
153737	Kirkwood Community College	
153922	Marshalltown Community College	
153977	Mercy College of Health Sciences	
154059	North Iowa Area Community College	
154110	Northeast Iowa Community College	
154129	Northwest Iowa Community College	
154262	St Luke's College	
154378	Southeastern Community College	
154396	Southwestern Community College	
154572	Western Iowa Tech Community College	
*/

//FL (Online only) Ended in 2020
****************************************************************************
*Eligible programs: "Complete Florida offers more than 130 online degree programs from 14 accredited public and private colleges and universities. Degree programs are organized under five areas of study: Business & Management, Education, Information Technology and Healthcare."

replace elg_any=1 if stabbr=="FL" & unitid==132471|unitid==132903|unitid==133702|unitid==133951| ///
unitid==134608|unitid==135717|unitid==136330|unitid==136516|unitid==137078|unitid==137351| ///
unitid==137476|unitid==138354|unitid==367884|unitid==433660
replace elg_bach=1 if stabbr=="FL" & elg_any==1
replace elg_assoc=1 if stabbr=="FL" & elg_any==1

*Certs are not eligible 


/*LIST OF ELIGIBLE INSTITUTIONS

132471	Barry University	
132903	University of Central Florida	
133702	Florida State College at Jacksonville
133951	Florida International University	
134608	Indian River State College	
135717	Miami Dade College	
136330	Palm Beach Atlantic University	
136516	Polk State College	
137078	St Petersburg College	
137351	University of South Florida	
137476	St. Thomas University
138354	The University of West Florida
367884	Hodges University	
433660	Florida Gulf Coast University	
*/


//KY
*******************************************************************************
*Eligible Programs: Applies for Bachelors degrees only 

replace elg_any=1 if unitid==156620|unitid==157058|unitid==157085|unitid==157289|unitid==157386|unitid==157401|unitid==157447|unitid==157951

replace elg_bach=1 if elg_any==1 & stabbr=="KY"


/*List of Eligible Institutions
Eastern Kentucky University
Kentucky State University
Morehead State University
Murray State University 
Northern Kentucky University
University of Kentucky
University of Louisville
Western Kentucky University 
*/

	
//MS
*******************************************************************************
*Eligible Institutions: MS public university or community colleges
*Eligible program: "Be working towards completing your first college degree (associate or bachelor's)"

replace elg_any=1 if stabbr=="MS"

replace elg_bach=1 if stabbr=="MS"

replace elg_assoc=1 if stabbr=="MS" 

*cert not eligible 

//MD
*******************************************************************************
*Eligible Institutions: All Public in MD 
*Eligible Programs: NOT Cert Eligible 


replace elg_any=1 if stabbr=="MD"

replace elg_bach=1 if stabbr=="MD"

replace elg_assoc=1 if stabbr=="MD"



//*Add Implementation Year
**********************************************************
gen implementation_yr=.

//WV 
replace implementation_yr=2003 if stabbr=="WV" & elg_any==1

//TN Hope
replace implementation_yr=2005 if stabbr=="TN" & elg_any==1

//KY
replace implementation_yr=2008 if stabbr=="KY" & elg_any==1

//LA
replace implementation_yr=2010 if stabbr=="LA" & elg_any==1

//FL
replace implementation_yr=2013 if stabbr=="FL" & elg_any==1

//IN
replace implementation_yr=2016 if stabbr=="IN" & elg_any==1

//MS
replace implementation_yr=2016 if stabbr=="MS" & elg_any==1

//ID
replace implementation_yr=2018 if stabbr=="ID" & elg_any==1

//MN
replace implementation_yr=2018 if stabbr=="MN" & elg_any==1 //ends 2021

//MD 
replace implementation_yr=2018 if stabbr=="MD" & elg_any==1

***late
/*
//IA
replace implementation_yr=2019 if stabbr=="IA" & elg_any==1

//ME
replace implementation_yr=2020 if stabbr=="ME" & elg_any==1

//MI
replace implementation_yr=2020 if stabbr=="MI" & elg_any==1

//MO
replace implementation_yr=2020 if stabbr=="MO" & elg_any==1

//UT
replace implementation_yr=2021 if stabbr=="UT" & elg_any==1
*/



//create level dummies for loops
gen all=1
gen assoc=(iclevel==0)
gen bach=(iclevel==1)

//Define "Strong" Treated Group 
********************************************************************************
*Defined as: 1) simple application: you apply through the state not through institution OR you are automatically considered when submitting the FAFSA 2) program comes with a guaranteed scholarship that can be used towards tuition.

gen elg_strong_stabbr=1 if  stabbr=="ID"| stabbr=="IN"| stabbr=="LA"| ///
 stabbr=="TN"|stabbr=="MS"| stabbr=="MD"  //define states with strong policies 

gen elg_strong=0
replace elg_strong=1 if elg_any==1 & elg_strong_stabbr==1

gen elg_bach_strong=0
replace elg_bach_strong=1 if elg_bach==1 & elg_strong_stabbr==1

gen elg_assoc_strong=0
replace elg_assoc_strong=1 if elg_assoc==1 & elg_strong_stabbr==1

gen elg_cert_strong=0
replace elg_cert_strong=1 if elg_cert==1 & elg_strong_stabbr==1

//Generate Indicators for Each Treatment Wave
********************************************************************************

g wv_all=(elg_any==1)
label var wv_all "All Implementers"


g wv_03=(stabbr=="WV" & elg_any==1)
replace wv_03=. if elg_any==1 & stabbr!="WV"
label var wv_03 "2003: WV"

g wv_05=(stabbr=="TN" & elg_any==1)
replace wv_05=. if elg_any==1 & stabbr!="TN"
label var wv_05 "2005: TN"

g wv_08=(stabbr=="KY" & elg_any==1)
replace wv_08=. if elg_any==1 & stabbr!="KY"
label var wv_08 "2008: KY"

g wv_10=(stabbr=="LA" & elg_any==1)
replace wv_10=. if elg_any==1 & stabbr!="LA"
label var wv_10 "2010: LA"

g wv_13=(stabbr=="FL" & elg_any==1)
replace wv_13=. if elg_any==1 & stabbr!="FL"
label var wv_13 "2013: FL"

g wv_16=(stabbr=="IN" & elg_any==1)
replace wv_16=. if elg_any==1 & stabbr!="IN"
replace wv_16=1 if stabbr=="MS" & elg_any==1
label var wv_16 "2016: IN, MS"

g wv_18=(stabbr=="ID" & elg_any==1)
replace wv_18=. if elg_any==1 & stabbr!="ID"
replace wv_18=1 if stabbr=="MN" & elg_any==1
replace wv_18=1 if stabbr=="MD" 
label var wv_18 "2018: ID, MN, MD"

g wv_19=(stabbr=="IA" & elg_any==1)
replace wv_19=. if elg_any==1 & stabbr!="IA"
label var wv_19 "2019: IA"

g wv_20=(stabbr=="ME" & elg_any==1)
replace wv_20=. if elg_any==1 & stabbr!="ME"
replace wv_20=1 if stabbr=="MI" & elg_any==1
replace wv_20=1 if stabbr=="MO" & elg_any==1
label var wv_20 "2020: ME, MI, MO"

g wv_21=(stabbr=="UT" & elg_any==1)
replace wv_21=. if elg_any==1 & stabbr!="UT" 
label var wv_21 "2021: UT"

g comp_group=1 if elg_any==0

//this is leaving untreated institutions within treated states in the comparison group 


********************************************************************************
/*Clean Control Variables */
********************************************************************************

//Institution Characteristics
********************************************************************************

//recode iclevel so it is 0/1 (easier to work with)

replace iclevel=0 if iclevel==2

label define iclevel_labels   	  	  1 "4-year" /// 
									  0 "2-year" 
label values iclevel iclevel_labels

//Fill in missing values for instructional staff with prior year 
/*NOTE: 2020 instructional staff file is just not included in IPEDS so that whole 
year needs to be filled in */
local insts tot prof other_academic nonacademic 

foreach myvar of local insts{
sort unitid year
by unitid: replace inst_staff_`myvar'=inst_staff_`myvar'[_n+1] if missing(inst_staff_`myvar')

}

//gen student-faculty ratio
gen sfr=c_ug_total/inst_staff_tot

label var sfr "Student Faculty Ratio"

//gen ppe 
gen inst_ppe=inst_spending/c_ug_total 
gen academic_support_ppe=academic_support_spending/c_ug_total 
gen student_services_ppe=student_services_spending/c_ug_total

label var student_services_ppe "Spending per undergraduate student on student services"
label var inst_ppe "Spending per undergraduate student on instruction"
label var academic_support_ppe "Spending per undergraduate student on academics"

//clean up weird ppe variables-2002
sum student_services_ppe if year==2002 & elg_any==1,detail 
replace student_services_ppe=r(p95) if student_services_ppe>r(p99) & year==2002

sum academic_support_ppe if year==2002,detail
replace academic_support_ppe=r(p95) if academic_support_ppe>r(p95) & year==2002

sum inst_ppe if year==2002,detail
replace inst_ppe=r(p95) if inst_ppe>r(p95) & year==2002

//clean up weird ppe variables-2009
sum student_services_ppe if year==2009 & elg_any==1,detail 
replace student_services_ppe=r(p95) if student_services_ppe>r(p99) & year==2009

sum academic_support_ppe if year==2009,detail
replace academic_support_ppe=r(p95) if academic_support_ppe>r(p95) & year==2009

sum inst_ppe if year==2009,detail
replace inst_ppe=r(p95) if inst_ppe>r(p95) & year==2009

//clean up weird ppe variables-2017
sum student_services_ppe if year==2017 & elg_any==1,detail 
replace student_services_ppe=r(p95) if student_services_ppe>r(p99) & year==2017

sum academic_support_ppe if year==2017,detail
replace academic_support_ppe=r(p95) if academic_support_ppe>r(p95) & year==2017

sum inst_ppe if year==2017,detail
replace inst_ppe=r(p95) if inst_ppe>r(p95) & year==2017





//State and County Covars 
********************************************************************************

//Fill in 2020 population values for 2021 (2021 data not availiable yet) 
local pops st_pop_total_as st_pop_under18_as st_pop_1824_as st_pop_2539_as st_pop_abv40_as st_pop_total_bk st_pop_abv25_as st_pop_total_bk st_pop_under18_bk st_pop_2539_bk st_pop_abv40_bk st_pop_abv25_bk st_pop_total_hsp st_pop_under18_hsp st_pop_1824_hsp st_pop_2539_hsp st_pop_abv40_hsp st_pop_abv25_hsp st_pop_total_na st_pop_under18_na st_pop_1824_na st_pop_2539_na st_pop_abv40_na st_pop_abv25_na st_pop_total_wh st_pop_under18_wh st_pop_1824_wh st_pop_2539_wh st_pop_abv40_wh st_pop_abv25_wh st_pop_under18 st_pop_tot st_pop_1824 st_pop_2539 st_pop_abv40 st_pop_abv25 c_pop_total_as c_pop_under18_as c_pop_1824_as c_pop_2539_as c_pop_abv40_as c_pop_abv25_as c_pop_total_bk c_pop_under18_bk c_pop_1824_bk c_pop_2539_bk c_pop_abv40_bk c_pop_abv25_bk c_pop_total_hsp c_pop_under18_hsp c_pop_1824_hsp c_pop_2539_hsp c_pop_abv40_hsp c_pop_abv25_hsp c_pop_total_na c_pop_under18_na c_pop_1824_na c_pop_2539_na c_pop_abv40_na c_pop_abv25_na c_pop_total_wh c_pop_1824_wh c_pop_under18_wh c_pop_2539_wh c_pop_abv40_wh c_pop_abv25_wh c_pop_tot c_pop_under18 c_pop_1824 c_pop_2539 c_pop_abv40 c_pop_abv25

foreach myvar of local pops{
sort stabbr county_fips year
bys stabbr county_fips: replace `myvar'=`myvar'[_n-1] if year==2021

}

//gen population percentages
local pops st_pop_abv25_as st_pop_abv25_bk st_pop_abv25_hsp st_pop_abv25_na st_pop_abv25_wh

foreach myvar of local pops {
	gen `myvar'_perc=(`myvar'/st_pop_abv25)*100
}

local pops st_pop_total_as st_pop_total_bk st_pop_total_hsp st_pop_total_na st_pop_total_wh

foreach myvar of local pops {
	gen `myvar'_perc=(`myvar'/st_pop_tot)*100
}

local pops2 c_pop_abv25_as c_pop_abv25_bk c_pop_abv25_hsp c_pop_abv25_na c_pop_abv25_wh

foreach myvar of local pops2 {
	gen `myvar'_perc=(`myvar'/c_pop_abv25)*100
}

local pops2 c_pop_total_as c_pop_total_bk c_pop_total_hsp c_pop_total_na c_pop_total_wh

foreach myvar of local pops2 {
	gen `myvar'_perc=(`myvar'/c_pop_tot)*100
}

gen st_pop_abv25_perc=(st_pop_abv25/st_pop_tot)*100
gen c_pop_abv25_perc=(c_pop_abv25/c_pop_tot)*100

//gen number of institutions per state
bys stabbr year: egen count_st_inst_4=count(unitid) if iclevel==1
bys stabbr year: egen count_st_inst_2=count(unitid) if iclevel==2

label var count_st_inst_4 "Number of 4-year institutions in state"
label var count_st_inst_2 "Number of 2-year institutions in state"

//gen proportion adults 
gen prop_c_ug_over25= c_ug_over25/ug_total

//add variable labels
/*******************************************************************************/

label var c_pop_tot "County total population" 
label var c_pop_abv25_perc "Percent of county population above 25"
label var c_pop_abv25_as_perc "Percent of county population above 25, Asian"
label var c_pop_abv25_bk_perc "Percent of county population above 25, Black"
label var c_pop_abv25_hsp_perc "Percent of county population above 25, Hispanic"
label var c_pop_abv25_wh_perc "Percent of county population above 25, White"
label var st_pop_tot "State total population"
label var st_pop_abv25_perc "Percent of state population above 25"
label var st_pop_abv25_as_perc "Percent of state population above 25, Asian"
label var st_pop_abv25_bk_perc "Percent of state population above 25, Black"
label var st_pop_abv25_hsp_perc "Percent of state population above 25, Hispanic"
label var st_pop_abv25_wh_perc "Percent of state population above 25, White"
label var saipe_c_pov "Percent of county living in poverty"
label var saipe_c_inc "County median income"
label var bls_unemploy "County unemployment rate"
label var med_inc_fred "State median income"
label var fred_unemploy_rate "State unemployment rate"



//time to event variables for event studies
/*******************************************************************************/
g timetoevent = year-implementation_yr

save ${adir}clean_IPEDS.dta, replace 

//create state-level poverty measure
/*******************************************************************************/

preserve

collapse (mean) saipe_c_pov, by(stabbr year)

rename saipe_c_pov saipe_st_pov

save ${adir}state_pov, replace

restore

use ${adir}clean_IPEDS.dta, clear
drop _merge

merge m:1 year stabbr using ${adir}state_pov


//set globals
global covars_geo c_pop_tot c_pop_abv25_perc c_pop_abv25_as_perc c_pop_abv25_bk_perc c_pop_abv25_hsp_perc c_pop_abv25_wh_perc saipe_c_pov saipe_c_inc bls_unemploy st_pop_tot st_pop_abv25_perc st_pop_abv25_as_perc st_pop_abv25_bk_perc st_pop_abv25_hsp_perc st_pop_abv25_wh_perc med_inc_fred fred_unemploy_rate saipe_st_pov st_pop_total_as st_pop_total_bk st_pop_total_hsp st_pop_total_na st_pop_total_wh st_pop_tot c_pop_tot c_pop_total_as c_pop_total_bk c_pop_total_hsp c_pop_total_na c_pop_total_wh tuition2 sfr academic_support_ppe inst_ppe student_services_ppe   

g missing=0

foreach myvar of global covars_geo{
replace missing=1 if `myvar'==.

}



/*******************************************************************************/
//Fill in missing values in covariates 
/*******************************************************************************/

*state-level:
/*******************************************************************************/

/*st_pop_tot st_pop_abv25_perc st_pop_abv25_as_perc st_pop_abv25_bk_perc st_pop_abv25_hsp_perc st_pop_abv25_wh_perc med_inc_fred fred_unemploy_rate saipe_st_pov*/ 

//one value of state population is missing due to a missing value in State var (merged issue), fill in by hand

replace st_pop_tot=39368078 if year==2021 & stabbr=="CA"
replace st_pop_abv25_perc=68.51323 if year==2021 & stabbr=="CA"
replace st_pop_abv25_as_perc= 17.31107 if year==2021 & stabbr=="CA" 
replace st_pop_abv25_bk_perc= 6.190156 if year==2021 & stabbr=="CA" 
replace st_pop_abv25_wh_perc= 41.6547 if year==2021 & stabbr=="CA" 
replace st_pop_abv25_hsp_perc= 34.31832 if year==2021 & stabbr=="CA"
replace st_pop_total_as= st_pop_total_as[_n-1] if year==2021 & stabbr=="CA"
replace st_pop_total_bk= st_pop_total_bk[_n-1] if year==2021 & stabbr=="CA"
replace st_pop_total_hsp= st_pop_total_hsp[_n-1] if year==2021 & stabbr=="CA"
replace st_pop_total_na= st_pop_total_na[_n-1] if year==2021 & stabbr=="CA"
replace st_pop_total_wh= st_pop_total_wh[_n-1] if year==2021 & stabbr=="CA"



*MISSING: none.


*county-level: fill in state mean
/*******************************************************************************/
/*c_pop_tot c_pop_abv25_perc c_pop_abv25_as_perc c_pop_abv25_bk_perc c_pop_abv25_hsp_perc c_pop_abv25_wh_perc saipe_c_pov saipe_c_inc bls_unemploy*/

local c_vars pop_tot pop_abv25_perc pop_abv25_as_perc pop_abv25_bk_perc pop_abv25_hsp_perc pop_abv25_wh_perc 

foreach myvar of local c_vars{
	replace c_`myvar'=st_`myvar' if c_`myvar'==.
}

replace saipe_c_inc=med_inc_fred if saipe_c_inc==.
replace bls_unemploy=fred_unemploy_rate if bls_unemploy==.
replace saipe_c_pov=saipe_st_pov if saipe_c_pov==.

*Missing: none


//institution-level: enrollment vars 
/*******************************************************************************/ 

***Step 1: Fill in prior or next year value for enrollment variables 

g missing_covar=0

local covars c_ug_over25 c_pt_over25 c_fte_over25

foreach myvar of local covars{
	
	*gen flag to check work 
	replace missing_covar=1 if `myvar'==.
	egen flag_`myvar' = max(missing_covar), by(unitid)

	*replace with one year before
	g `myvar'_crt=`myvar'
	sort unitid year 
	by unitid: replace `myvar'=`myvar'[_n-1] if missing(`myvar')

	*replace with one year after is still missing
	sort unitid year 
	by unitid: replace `myvar'=`myvar'_crt[_n+1] if missing(`myvar')
	
}



//institution-level: 
********************************************************************
/*tuition2 sfr academic_support_ppe inst_ppe student_services_ppe c_ug_total */

**Step One: replace missing values with state by level by year mean 


preserve
collapse(mean) tuition2 sfr academic_support_ppe inst_ppe student_services_ppe c_ug_total c_pt_total c_fte_total, by(iclevel stabbr year)
rename * *_col
rename stabbr_col stabbr
rename iclevel_col iclevel 
rename year_col year 

save ${adir}inst_covars, replace

restore

drop _merge

merge m:1 stabbr iclevel year using ${adir}inst_covars

local covars tuition2 sfr academic_support_ppe inst_ppe student_services_ppe c_ug_total

foreach myvar of local covars{
	replace `myvar'=`myvar'_col if missing(`myvar')
}




***Step Two: There are still some missing values, for example if all insts for a certain level were missing data for that year. Solution: fill in previous years' value

*missing: 

drop missing_covar
g missing_covar=0

local covars tuition2 sfr academic_support_ppe inst_ppe student_services_ppe c_ug_total c_pt_total c_fte_total

foreach myvar of local covars{
	
	*gen flag to check work 
	replace missing_covar=1 if `myvar'==.
	egen flag_`myvar' = max(missing_covar), by(unitid)

	*replace with one year before
	g `myvar'_crt=`myvar'
	sort unitid year 
	bys unitid: replace `myvar'=`myvar'[_n-1] if missing(`myvar'_crt) 
	
	*replace with one year after is still missing 
	sort unitid year 
	bys unitid: replace `myvar'=`myvar'[_n+1] if missing(`myvar'_crt)

}


***Step 3: 
*community college of Vermont is still missing SFR for many years, I am filling in the sfr from 2000 (last availiable year) for all years. 

replace sfr=22.02778 if sfr==. & unitid==230861


***missing: none
	


//gen year specific institution-level covars
********************************************************************************

local covars iclevel tuition2 sfr academic_support_ppe inst_ppe student_services_ppe 

foreach myvar of local covars{
	sort unitid year
	by unitid: egen `myvar'_02 = total(cond(year == 2002, `myvar', .))
}

foreach myvar of local covars{
	sort unitid year
	by unitid: egen `myvar'_09 = total(cond(year == 2009, `myvar', .))
}

foreach myvar of local covars{
	sort unitid year
	by unitid: egen `myvar'_17 = total(cond(year == 2017, `myvar', .))
}
	
//create enrollment and completion percentages 
********************************************************************************

//gen enrollment over 25 percentages  
local fte_vars c_fte_under25 c_fte_over25 c_fte_2224 c_fte_2529 c_fte_3034 c_fte_3539 c_fte_4049 c_fte_5064 c_fte_over65 
local ug_vars c_ug_under25 c_ug_over25 c_ug_2224 c_ug_2529 c_ug_3034 c_ug_3539 c_ug_4049 c_ug_5064 c_ug_over65
local pt_vars c_pt_under25 c_pt_over25 c_pt_2224 c_pt_2529 c_pt_3034 c_pt_3539 c_pt_4049 c_pt_5064 c_pt_over65 

foreach myvar of local fte_vars{
gen perc_`myvar'= `myvar'/c_fte_total
}

foreach myvar of local ug_vars{
gen perc_`myvar'= `myvar'/c_ug_total
}

foreach myvar of local pt_vars{
gen perc_`myvar'= `myvar'/c_pt_total
}

label var c_ug_over25 "Undergraduate enrollment over 25, corrected"
label var perc_c_fte_over25 "Percent of full-time undergraduate enrollment over 25, corrected"
label var perc_c_pt_over25 "Percent of part-time undergraduate enrollment Over 25, corrected"

//gen completion percentages
local dg assoc bach 

foreach var of local dg {

local `var'_vars dg_1824_`var' dg_2539_`var' dg_abv40_`var'

foreach myvar of local `var'_vars{
gen perc_`myvar'= `myvar'/dg_tot_`var'
}

//add var labels 
label var perc_dg_1824_`var' "Percent `var' Degrees Awarded to 18-24 year olds"
label var perc_dg_2539_`var' "Percent `var' Degrees Awarded to 25-39 year olds"
label var perc_dg_abv40_`var' "Percent `var' Degrees Awarded to 40+ year olds"

}

//gen logged outcome variables
********************************************************************************
//NOTE: 0s are now missing with logging 
gen log_c_ug_over25=log(c_ug_over25)
gen log_c_fte_over25=log(c_fte_over25)
gen log_c_pt_over25=log(c_pt_over25)
gen log_c_ug_under25=log(c_ug_under25)
gen log_c_ug_1821=log(c_ug_1821)

replace log_c_ug_under25=0 if log_c_ug_under25==.

drop flag*

//add fixed covariate values for San'tanna Robustness Checks 
********************************************************************************
*state-level-2002
********************************************************************************
local vars fred_unemploy_rate med_inc_fred saipe_st_pov 

foreach myvar of local vars{
	
	*recode treated
	sort unitid year
	by unitid: g `myvar'_fixed_temp=`myvar' if year==implementation_yr-1 & elg_any==1
	
	*recode comparison 
	by unitid: replace `myvar'_fixed_temp=`myvar' if year==2002 & elg_any==0
	
	*fill in values
	bys stabbr: egen `myvar'_fixed1=max(`myvar'_fixed_temp) if elg_any==1
	bys stabbr: egen `myvar'_fixed2=max(`myvar'_fixed_temp) if elg_any==0
	
	*make full var
	g `myvar'_fixed=`myvar'_fixed1 if elg_any==1
	replace `myvar'_fixed=`myvar'_fixed2 if elg_any==0
	
	drop `myvar'_fixed_temp `myvar'_fixed1 `myvar'_fixed2
	
}

*county-level 
local vars saipe_c_pov saipe_c_inc bls_unemploy

foreach myvar of local vars{
	
	*recode treated
	sort unitid year
	by unitid: g `myvar'_fixed_temp=`myvar' if year==implementation_yr-1 & elg_any==1
	
	*recode comparison 
	by unitid: replace `myvar'_fixed_temp=`myvar' if year==2002 & elg_any==0
	
	*fill in values
	bys county_fips: egen `myvar'_fixed1=max(`myvar'_fixed_temp) if elg_any==1
	bys county_fips: egen `myvar'_fixed2=max(`myvar'_fixed_temp) if elg_any==0
	
	*make full var
	g `myvar'_fixed=`myvar'_fixed1 if elg_any==1
	replace `myvar'_fixed=`myvar'_fixed2 if elg_any==0
	
	drop `myvar'_fixed_temp `myvar'_fixed1 `myvar'_fixed2
	
}
	
*fill in missing values with state average

replace saipe_c_pov_fixed=saipe_st_pov_fixed if missing(saipe_c_pov_fixed)
replace saipe_c_inc_fixed=med_inc_fred_fixed if missing(saipe_c_inc_fixed)
replace bls_unemploy_fixed=fred_unemploy_rate_fixed if missing(bls_unemploy_fixed)

rename saipe_c_pov_fixed saipe_c_pov_fixed02
rename saipe_c_inc_fixed saipe_c_inc_fixed02
rename bls_unemploy_fixed bls_unemploy_fixed02

drop saipe_st_pov_fixed med_inc_fred_fixed fred_unemploy_rate_fixed

*state-level-2012
********************************************************************************
local vars fred_unemploy_rate med_inc_fred saipe_st_pov 

foreach myvar of local vars{
	
	*recode treated
	sort unitid year
	by unitid: g `myvar'_fixed_temp=`myvar' if year==implementation_yr-1 & elg_any==1
	
	*recode comparison 
	by unitid: replace `myvar'_fixed_temp=`myvar' if year==2012 & elg_any==0
	
	*fill in values
	bys stabbr: egen `myvar'_fixed1=max(`myvar'_fixed_temp) if elg_any==1
	bys stabbr: egen `myvar'_fixed2=max(`myvar'_fixed_temp) if elg_any==0
	
	*make full var
	g `myvar'_fixed=`myvar'_fixed1 if elg_any==1
	replace `myvar'_fixed=`myvar'_fixed2 if elg_any==0
	
	drop `myvar'_fixed_temp `myvar'_fixed1 `myvar'_fixed2
	
}

*county-level 
local vars saipe_c_pov saipe_c_inc bls_unemploy

foreach myvar of local vars{
	
	*recode treated
	sort unitid year
	by unitid: g `myvar'_fixed_temp=`myvar' if year==implementation_yr-1 & elg_any==1
	
	*recode comparison 
	by unitid: replace `myvar'_fixed_temp=`myvar' if year==2012 & elg_any==0
	
	*fill in values
	bys county_fips: egen `myvar'_fixed1=max(`myvar'_fixed_temp) if elg_any==1
	bys county_fips: egen `myvar'_fixed2=max(`myvar'_fixed_temp) if elg_any==0
	
	*make full var
	g `myvar'_fixed=`myvar'_fixed1 if elg_any==1
	replace `myvar'_fixed=`myvar'_fixed2 if elg_any==0
	
	drop `myvar'_fixed_temp `myvar'_fixed1 `myvar'_fixed2
	
}

	
*fill in missing values with state average

replace saipe_c_pov_fixed=saipe_st_pov_fixed if missing(saipe_c_pov_fixed)
replace saipe_c_inc_fixed=med_inc_fred_fixed if missing(saipe_c_inc_fixed)
replace bls_unemploy_fixed=fred_unemploy_rate_fixed if missing(bls_unemploy_fixed)

rename saipe_c_pov_fixed saipe_c_pov_fixed12
rename saipe_c_inc_fixed saipe_c_inc_fixed12
rename bls_unemploy_fixed bls_unemploy_fixed12



********************************************************************************
//Create Comparison Groups
********************************************************************************

//Remove Large Systems
gen comp_group_nolarge=1 
replace comp_group_nolarge=0 if stabbr=="CA"|stabbr=="NY"

//Southern/Midwest States only 
gen comp_group_south_midwest=1 if region=="South"| region=="Midwest"

//Similar State Enrollment Population
sum st_pop_tot if elg_any==1 & year==2002
scalar t_mean=r(mean)
scalar t_sd=r(sd)
sort unitid year
gen comp_group_pop02_temp=0
replace comp_group_pop02_temp=1 if year==2002 & st_pop_tot<t_mean+t_sd & st_pop_tot>t_mean-t_sd
replace comp_group_pop02_temp=1 if elg_any==1
by unitid: egen comp_group_pop02=max(comp_group_pop02_temp)
drop comp_group_pop02_temp

sum st_pop_tot if elg_any==1 & year==2012
scalar t_mean=r(mean)
scalar t_sd=r(sd)
sort unitid year
gen comp_group_pop12_temp=0
replace comp_group_pop12_temp=1 if year==2012 & st_pop_tot<t_mean+t_sd & st_pop_tot>t_mean-t_sd
replace comp_group_pop12_temp=1 if elg_any==1
by unitid: egen comp_group_pop12=max(comp_group_pop12_temp)
drop comp_group_pop12_temp


//Similar County Economic Strength in 2002 
sum saipe_c_inc if elg_any==1 & year==2002 
scalar t_mean=r(mean)
scalar t_sd=r(sd)

gen comp_group_inc02_temp=0
replace comp_group_inc02_temp=1 if year==2002 & saipe_c_inc<t_mean+t_sd & saipe_c_inc>t_mean-t_sd
replace comp_group_inc02_temp=1 if elg_any==1
by unitid: egen comp_group_inc02=max(comp_group_inc02_temp)
drop comp_group_inc02_temp

sum saipe_c_inc if elg_any==1 & year==2012
scalar t_mean=r(mean)
scalar t_sd=r(sd)

gen comp_group_inc12_temp=0
replace comp_group_inc12_temp=1 if year==2012 & saipe_c_inc<t_mean+t_sd & saipe_c_inc>t_mean-t_sd
replace comp_group_inc12_temp=1 if elg_any==1
by unitid: egen comp_group_inc12=max(comp_group_inc12_temp)
drop comp_group_inc12_temp


//define groups
*******************************************************************************
drop all 
g all=1
g no_ivy=1 
replace no_ivy=0 if unitid==150987
g no_la=1
replace no_la=0 if stabbr=="LA"

drop bach assoc  

g bach=(iclevel==1)
g assoc=(iclevel==0)
replace assoc=0 if elg_assoc==0 & elg_cert==1
g cert=(iclevel==0)
replace cert=0 if elg_assoc==1 & elg_cert==0

g strong=1
replace strong=0 if elg_any==1 & elg_strong!=1

g not_yet=1


//final clean up 
********************************************************************************


drop if c_ug_over25==.| log_c_ug_over25==. //drop out missing outcome institutions that will be excluded from analysis 

save ${adir}clean_IPEDS.dta, replace

/********************************************************************************
 Count of Insitutions by County
********************************************************************************/
use ${adir}clean_IPEDS.dta, clear
g inst_count=1
keep county_fips_correct stabbr year inst_count
drop if county_fips==""
sort stabbr county_fips_correct year
collapse (sum) inst_count, by(county_fips_correct stabbr year)
rename inst_count c_inst_count 
label var c_inst_count "count of institutions in county"

save ${adir}county_inst_count.dta, replace 

use ${adir}clean_IPEDS.dta, clear
drop _merge
merge m:1 county_fips_correct year stabbr using ${adir}county_inst_count.dta

*fill in the state average for missing data 
bys stabbr year: egen mean_s_inst_count=mean(c_inst_count)
replace c_inst_count=mean_s_inst_count if missing(c_inst_count)

*fill in prior year for 2021
replace c_inst_count=c_inst_count[_n-1] if missing(c_inst_count)

//fill in more covariates
 *******************************************************************************

*step 1: fill in state average for missing county-level covars

local vars c_pop_tot c_pop_total_as c_pop_total_bk c_pop_total_hsp c_pop_total_na c_pop_total_wh

foreach myvar of local vars{
bys stabbr year: egen st_avg_`myvar'=mean(`myvar')
replace `myvar'=st_avg_`myvar' if missing(`myvar')
}


*step 2: HI is still missing values for 1998 and 1999
gsort stabbr -year 

local vars c_pop_tot c_pop_total_as c_pop_total_bk c_pop_total_hsp c_pop_total_na c_pop_total_wh

foreach myvar of local vars{
replace `myvar'=`myvar'[_n-1] if missing(`myvar')
}

*step 3: fill in state average for institutions
local vars tuition2 sfr academic_support_ppe inst_ppe student_services_ppe c_inst_count

foreach myvar of local vars{
bys stabbr year: egen st_avg_`myvar'=mean(`myvar')
replace `myvar'=st_avg_`myvar' if missing(`myvar')
}

replace log_c_ug_1821=0 if log_c_ug_1821==.


rename log_dg_1824_allcert log_dg_1824_cert

//Recode iclevel for College of Southern Idaho--treated institution added to data after policy implementation, iclevel=1 but mostly awards associates (only 1 bachelor's degree awarded) 
replace iclevel=0 if unitid==142559 

/*******************************************************************************
 CODE SECTION: Save Cleaned File
*******************************************************************************/
save ${adir}clean_IPEDS.dta, replace

//use ${adir}clean_IPEDS.dta, clear





