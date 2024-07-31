********************************************************************************
//Project: Adult Reconnect
//Author: Adela Soliz, Coral Flanagan
//Date: 2022-04-12
//Purpose: Merge Data Files 
********************************************************************************

/*******************************************************************************
FILE STRUCTURE
This do-file is set up to work with the following file structure

main folder contains four subfolders: 'scripts', 'data' (contains 'raw' and 'cleaned'), 'docs', 'graphics'')
*******************************************************************************/
capture log close		
set more off            
clear all               
macro drop _all        

set scheme cleanplots, perm 

//Set Working Directory 
cd "/Users/coralflanagan1/Desktop/projects/adult_reconnect/scripts" //set working directory to scripts

//Set Data Directory 

global ddir "../data/raw/"
global adir "../data/cleaned/"
global gdir "../graphics/"
global gtype png
global ttype rtf
set scheme s1color

exit
/*******************************************************************************
CLEAN: 
These first sections of code clean each data file and selects relevant variables 
so they are ready to be merged.
*******************************************************************************/

/*******************************************************************************
 CODE SECTION: Institutional Characteristics: Directory Information 
 
UNITID-unique identifier
INSTNM- institution name
FIPS- state fips code
STABBR-abbreviation of state in which inst is located
ICLEVEL-level of institutions programs. 
	1 "four or more years"
	2 "at least 2 but less than 4"
	3 "less than 2 years (below associate)"
	-3 "not availiable"
SECTOR-Level and control. 
	 0 "Administrative Unit"
	 1 "Public, 4-year or above"
     2 "Private not-for-profit, 4-year or above"
     3 "Private for-profit, 4-year or above"
     4 "Public, 2-year"
     5 "Private not-for-profit, 2-year"
     6 "Private for-profit, 2-year"
     7 "Public, less-than 2-year"
     8 "Private not-for-profit, less-than 2-year"
     9 "Private for-profit, less-than 2-year"
     99 "Sector unknown (not active)"
CONTROL-
	1 "Public"
	2 "Private not-for-profit"
	3 "Private for-profit"
	-3 "{Not available}"
	
PSET4FLG-
	1 "Title IV postsecondary institution"
	2 "Non-Title IV postsecondary institution",add
	3 "Title IV NOT primarily postsecondary institution",add
	6 "Non-Title IV postsecondary institution that is NOT open to the  	
	public",add
	9 "Institution is not active in current universe",add

DEGGRANT-
	1 "Degree-granting"
	2 "Nondegree-granting, primarily postsecondary",add
	-3 "{Not available}",add

COUNTYNM- county name 
	
CARNEGIE-Carnegie Classification (do not use in analysis)
 
*******************************************************************************/

***clean 1999 file separately because is has some differences with later files 
use ${ddir}hd1999.dta, clear 
keep unitid instnm fips stabbr control sector iclevel ugoffer carnegie hdegoffr opeflag countynm
gen year = 1999
gen deggrant=0 
replace deggrant=1 if hdegoffr!=0 & hdegoffr!=. //degree-granting (recording to match vars in later datasets)
drop hdegoffr
gen pset4flg=1
replace pset4flg=0 if opeflag==5|opeflag==6 //title-4 eligible (recording to match vars in later datasets)
drop opeflag 

replace countynm=subinstr(countynm, "COUNTY", "", .) 
tostring fips, replace

merge m:1 countynm fips using  ${ddir}county_crosswalk.dta //add in county fips 
destring fips, replace 
destring countycd, replace 
drop if _merge==2

***append all files together 
//NOTE: I do this in waves to include varas like countycd that are only availiable in later datasets 

foreach year of numlist 2000/2021{
	if `year'>1999 & `year'<2009{
		append using ${ddir}hd`year'.dta, ///
		keep(unitid instnm fips stabbr control sector iclevel ugoffer deggrant pset4flg carnegie )
		replace year=`year' if year==.
	}
   if `year'>2008 & `year'<2019{
		append using ${ddir}hd`year'.dta, ///
		keep(unitid instnm fips stabbr control sector iclevel ugoffer deggrant pset4flg countycd countynm carnegie)
		replace year=`year' if year==.
   } 
   if `year'>2018 & `year'<2022{
		append using ${ddir}hd`year'.dta, ///
		keep(unitid instnm fips stabbr control sector iclevel ugoffer deggrant pset4flg countycd countynm carnegie c18basic)
		replace year=`year' if year==.
   }
	
}


***add var/value labels

label variable ugoffer  "Undergraduate offering"
label variable deggrant "Degree-granting status"
label variable pset4flg "Postsecondary and Title IV institution indicator"
label variable iclevel  "Level of institution"
label variable c18basic "Carnegie Classification 2018: Basic"
rename countycd county_fips

label define label_iclevel 1 "Four or more years"
label define label_iclevel 2 "At least 2 but less than 4 years",add
label define label_iclevel 3 "Less than 2 years (below associate)",add
label define label_iclevel -3 "{Not available}",add
label values iclevel label_iclevel

label define label_sector 0 "Administrative Unit"
label define label_sector 1 "Public, 4-year or above",add
label define label_sector 2 "Private not-for-profit, 4-year or above",add
label define label_sector 3 "Private for-profit, 4-year or above",add
label define label_sector 4 "Public, 2-year",add
label define label_sector 5 "Private not-for-profit, 2-year",add
label define label_sector 6 "Private for-profit, 2-year",add
label define label_sector 7 "Public, less-than 2-year",add
label define label_sector 8 "Private not-for-profit, less-than 2-year",add
label define label_sector 9 "Private for-profit, less-than 2-year",add
label define label_sector 99 "Sector unknown (not active)",add
label values sector label_sector

label define label_pset4flg 1 "Title IV postsecondary institution"
label define label_pset4flg 2 "Non-Title IV postsecondary institution",add
label define label_pset4flg 3 "Title IV NOT primarily postsecondary institution",add
label define label_pset4flg 4 "Non-Title IV NOT primarily postsecondary institution",add
label define label_pset4flg 6 "Non-Title IV postsecondary institution that is NOT open to the public",add
label define label_pset4flg 9 "Institution is not active in current universe",add
label values pset4flg label_pset4flg

label define label_ugoffer 1 "Undergraduate degree or certificate offering"
label define label_ugoffer 2 "No undergraduate offering",add
label define label_ugoffer -3 "{Not available}",add
label values ugoffer label_ugoffer

label define label_control 1 "Public"
label define label_control 2 "Private not-for-profit",add
label define label_control 3 "Private for-profit",add
label define label_control -3 "{Not available}",add
label values control label_control

label define label_c18basic 1 "Associate^s Colleges: High Transfer-High Traditional"
label define label_c18basic 2 "Associate^s Colleges: High Transfer-Mixed Traditional/Nontraditional",add
label define label_c18basic 3 "Associate^s Colleges: High Transfer-High Nontraditional",add
label define label_c18basic 4 "Associate^s Colleges: Mixed Transfer/Career & Technical-High Traditional",add
label define label_c18basic 5 "Associate^s Colleges: Mixed Transfer/Career & Technical-Mixed Traditional/Nontraditional",add
label define label_c18basic 6 "Associate^s Colleges: Mixed Transfer/Career & Technical-High Nontraditional",add
label define label_c18basic 7 "Associate^s Colleges: High Career & Technical-High Traditional",add
label define label_c18basic 8 "Associate^s Colleges: High Career & Technical-Mixed Traditional/Nontraditional",add
label define label_c18basic 9 "Associate^s Colleges: High Career & Technical-High Nontraditional",add
label define label_c18basic 10 "Special Focus Two-Year: Health Professions",add
label define label_c18basic 11 "Special Focus Two-Year: Technical Professions",add
label define label_c18basic 12 "Special Focus Two-Year: Arts & Design",add
label define label_c18basic 13 "Special Focus Two-Year: Other Fields",add
label define label_c18basic 14 "Baccalaureate/Associate^s Colleges: Associate^s Dominant",add
label define label_c18basic 15 "Doctoral Universities: Very High Research Activity",add
label define label_c18basic 16 "Doctoral Universities: High Research Activity",add
label define label_c18basic 17 "Doctoral/Professional Universities",add
label define label_c18basic 18 "Master^s Colleges & Universities: Larger Programs",add
label define label_c18basic 19 "Master^s Colleges & Universities: Medium Programs",add
label define label_c18basic 20 "Master^s Colleges & Universities: Small Programs",add
label define label_c18basic 21 "Baccalaureate Colleges: Arts & Sciences Focus",add
label define label_c18basic 22 "Baccalaureate Colleges: Diverse Fields",add
label define label_c18basic 23 "Baccalaureate/Associate^s Colleges: Mixed Baccalaureate/Associate^s",add
label define label_c18basic 24 "Special Focus Four-Year: Faith-Related Institutions",add
label define label_c18basic 25 "Special Focus Four-Year: Medical Schools & Centers",add
label define label_c18basic 26 "Special Focus Four-Year: Other Health Professions Schools",add
label define label_c18basic 27 "Special Focus Four-Year: Engineering Schools",add
label define label_c18basic 28 "Special Focus Four-Year: Other Technology-Related Schools",add
label define label_c18basic 29 "Special Focus Four-Year: Business & Management Schools",add
label define label_c18basic 30 "Special Focus Four-Year: Arts, Music & Design Schools",add
label define label_c18basic 31 "Special Focus Four-Year: Law Schools",add
label define label_c18basic 32 "Special Focus Four-Year: Other Special Focus Institutions",add
label define label_c18basic 33 "Tribal Colleges",add
label define label_c18basic -2 "Not applicable, not in Carnegie universe (not accredited or nondegree-granting)",add
label values c18basic label_c18basic


***recode missing to "." 
mvdecode sector iclevel control ugoffer deggrant pset4flg, mv(-3)

***replace fill in missing countycodes 
gsort unitid -year
bysort unitid: carryforward county_fips if county_fips==., replace 

gsort unitid year 
bysort unitid: carryforward county_fips if county_fips==., replace 
drop if unitid==.

gsort unitid -year 
bysort unitid: carryforward countynm, replace 

*NOTE: there are still some institutions without a county fips..need to figure out what to do about this.  

***save file  
save ${ddir}inst_merged.dta, replace 

/*******************************************************************************
 CODE SECTION: Institutional Characteristics: Student Charges - Academic Year 
File end year represents beginning of fall of academic year i.e. 2018 = 2018-2019

TUITION2- In-state average tuition for full-time undergraduates charges to 
full-time undergraduate students for the full academic year 2018-19 

CHG2AY3-Published in-state tuition and fees 2018-19
Price of attendance for full-time, first-time undergraduate students 
for the FULL ACADEMIC YEAR: (Tuition and fees, books and supplies, room and 
board, and other expenses are those amounts used by your financial aid office 
for determining eligibility for student financial assistance) These data are 
published at the IPEDS College Navigator Web site.

*******************************************************************************/

***clean

use ${ddir}ic1999_ay.dta, clear 

***append

keep unitid chg2ay3 
gen tuition2=. 
gen year = 1999

local i 2000

	while `i' < 2022 {
		
	append using ${ddir}ic`i'_ay.dta, ///
		keep(unitid tuition2 chg2ay3)

	replace year = `i' if year == .
		
	local i = `i' + 1

	}
	
***add var/value labels
label variable tuition2 "In-state average tuition for full-time undergraduates"
label variable chg2ay3  "Published in-state tuition and fees"

rename chg2ay3 published_tuition_fees

***backfill 2000 for 1999 for average tuition since tuition2 is not included in that file  
sort unitid year 
by unitid: replace tuition2=tuition2[_n+1] if missing(tuition2)

***save 

save ${ddir}IPEDS_merged_stuchgsay.dta, replace  

/*******************************************************************************
 CODE SECTION: Fall Enrollment: Age Category
 
In general (different from some years):
EFAGE08 = Total Women
EFAGE05 = Total Full-time 
EFAGE09 = Grand Total* 
EFAGE06= Total Part-Time 

lstudy==2 "Undergraduate"

EFBAGE
1	All age categories total
2	Age under 25 total
3	Age under 18
4	Age 18-19
5	Age 20-21
6	Age 22-24
7	Age 25 and over total
8	Age 25-29
9	Age 30-34
10	Age 35-39
11	Age 40-49
12	Age 50-64
13	Age 65 and over
14	Age unknown

*********************************************************************************/


***append 1999, 2002-2020
//2000 and 2001 are formatted differently 

//clean 1999
use ${ddir}ef1999b.dta, clear
g year=1999
save ${ddir}ef199b_updated.dta, replace 


//append 2002-2020
use ${ddir}ef2002b.dta, clear
g year=2002

local i 2003
	
	while `i' < 2022 {
		
	append using ${ddir}ef`i'b.dta, keep (unitid line lstudy ef*)
	
	replace year = `i' if year == .

	di `i'
	
	local i = `i' + 1
	
} 

//add in 1999
append using ${ddir}ef1999b_updated.dta

//limit to undergrads 
keep if lstudy == 2

//reshape file so there is 1 observation per institution   
keep unitid year efbage efage05 efage06 efage08 efage09

codebook efbage

local vlist "efage05 efage06 efage08 efage09"

local j "efbage"
levelsof `j', local(J)

local ages All <25 <18 18-19 20-21 22-24 25> 25-29 30-34 35-39 40-49 50-64 65> UnKn

foreach var of varlist `vlist' {
    foreach age of local ages {
        local lablist "`lablist' `"`:variable label `var'' (`age')"'"
        }
    }
 
foreach var of varlist `vlist' {
    foreach j of local J {
        local newlist `newlist' `var'`j'
        }
    }
 
reshape wide efage05 efage06 efage08 efage09, i(unitid year)  j(efbage) 

noi di "`newlist'"
noi di `"`lablist'"'

//LABEL the new variables

foreach new of local newlist {
    gettoken lab lablist : lablist
    lab var `new'  "`lab'"
    }
	
save ${ddir}IPEDS_merged_fallenrl_age_incomplete.dta, replace

***clean and append 2000-2001
use ${ddir}ef2000b.dta, clear
g lstudy=1 //all are ug (undergrads are coded as 1 in 2001 ONLY and 2 in all other files)
g year=2000

append using ${ddir}ef2001b.dta
replace year=2001 if year==.
keep if lstudy==1 //keep ug only 

//there are no combined totals by gender in the 2000-2001 files, I need to create these separately
gen efage=efage01+efage02 //gen combined total (male +female)
rename efage02 efage_8

drop xefage01 xefage02 efage01 lstudy section

//reshape
reshape wide efage efage_8, i(unitid year)  j(line) 

//fill in zeros for missing values so that sums will work 
foreach x of varlist _all {
  replace `x' = 0 if(`x' == .)
} 

//rename

//total ug
gen efage091=efage25 //all ug
gen efage092=efage13+efage1+efage14+efage2+efage15+efage3+efage16+efage4 //all ug under 25
gen efage093=efage13+efage1 //all ug under 18
gen efage094=efage14+efage2 //ug 18-19
gen efage095=efage15+efage3 //ug 20-21
gen efage096=efage16+efage4 //ug 22-24
gen efage097=efage17+efage5+efage18+efage6+efage19+efage7+efage20+efage8+efage21+efage9+ ///
efage22+efage10 //ug over25
gen efage098=efage17+efage5 //ug 25-29 
gen efage099=efage18+efage6 //ug 30-34
gen efage0910=efage19+efage7 //ug 35-39
gen efage0911=efage20+efage8 //ug 40-49
gen efage0912=efage21+efage9 //ug 50-64
gen efage0913=efage22+efage10 //ug 65 and over 
gen efage0914=efage23+efage11 //ug age unknown


//fte
gen efage051=efage12 //all fte
gen efage052=efage1+efage2+efage3+efage4 //all ug under 25
gen efage053=efage1 //all ug under 18
gen efage054=efage2 //ug 18-19
gen efage055=efage3 //ug 20-21
gen efage056=efage4 //ug 22-24
gen efage057=efage5+efage6+efage7+efage8+efage9+efage10 //ug over25
gen efage058=efage5 //ug 25-29 
gen efage059=efage6 //ug 30-34
gen efage0510=efage7 //ug 35-39
gen efage0511=efage8 //ug 40-49
gen efage0512=efage9 //ug 50-64
gen efage0513=efage10 //ug 65 and over 
gen efage0514=efage11 //ug age unknown

//part-time
gen efage061=efage24 //all part-time
gen efage062=efage13+efage14+efage15+efage16 //all pt under 25
gen efage063=efage13 //all pt under 18
gen efage064=efage14 //pt 18-19
gen efage065=efage15 //pt 20-21
gen efage066=efage16 //pt 22-24
gen efage067=efage17+efage18+efage19+efage20+efage21+efage22 //pt over25
gen efage068=efage17 //pt 25-29 
gen efage069=efage18 //pt 30-34
gen efage0610=efage19 //pt 35-39
gen efage0611=efage20 //pt 40-49
gen efage0612=efage21 //pt 50-64
gen efage0613=efage22 //pt 65 and over 
gen efage0614=efage23 //pt age unknown 


//female 
gen efage081=efage_825 //all ug
gen efage082=efage_813+efage_81+efage_814+efage_82+efage_815+efage_83+efage_816+efage_84 //all ug under 25
gen efage083=efage_813+efage_81 //all ug under 18
gen efage084=efage_814+efage_82 //ug 18-19
gen efage085=efage_815+efage_83 //ug 20-21
gen efage086=efage_816+efage_84 //ug 22-24
gen efage087=efage_817+efage_85+efage_818+efage_86+efage_819+efage_87+efage_820+efage_88+ ///
efage_821+efage_89+efage_822+efage_810+efage_823+efage_811 //ug over25
gen efage088=efage_817+efage_85 //ug 25-29 
gen efage089=efage_818+efage_86 //ug 30-34
gen efage0810=efage_819+efage_87 //ug 35-39
gen efage0811=efage_820+efage_88 //ug 40-49
gen efage0812=efage_821+efage_89 //ug 50-64
gen efage0813=efage_822+efage_810 //ug 65 and over 
gen efage0814=efage_823+efage_811 //ug age unknown

//drop old vars
drop efage_81 efage1 efage_82 efage2 efage_83 efage3 efage_84 efage4 efage_85 efage5 ///
efage_86 efage6 efage_87 efage7 efage_88 efage8 efage_89 efage9 efage_810 efage10 ///
efage_811 efage11 efage_812 efage12 efage_813 efage13 efage_814 efage14 efage_815 efage15 ///
efage_816 efage16 efage_817 efage17 efage_818 efage18 efage_819 efage19 efage_820 efage20 ///
efage_821 efage21 efage_822 efage22 efage_823 efage23 efage_824 efage24 efage_825 efage25
	
**append with other files  

append using ${ddir}IPEDS_merged_fallenrl_age_incomplete.dta

***label

//all ug
rename efage091 ug_total
rename efage092 ug_under25
rename efage094 ug_1819
rename efage095 ug_2021
rename efage096 ug_2224
rename efage097 ug_over25
rename efage098 ug_2529
rename efage099 ug_3034
rename efage0910 ug_3539
rename efage0911 ug_4049
rename efage0912 ug_5064
rename efage0913 ug_over65 


label var ug_total "Total UG enrollment"
label var ug_under25 "UG enrl Under 25"
label var ug_over25 "UG enrl Over 25"
label var ug_1819 "UG enrl 18-19"
label var ug_2021 "UG enrl 20-21"
label var ug_2224 "UG enrl 22-24"
label var ug_2529 "UG enrl 25-29"
label var ug_3034 "UG enrl 30-34"
label var ug_3539 "UG enrl 35-39"
label var ug_4049 "UG enrl 40-49"
label var ug_5064 "UG enrl 50-64"
label var ug_over65 "UG enrl over65" 

//full-time
rename efage051 fte_total
rename efage052 fte_under25
rename efage057 fte_over25
rename efage054 fte_1819
rename efage055 fte_2021
rename efage056 fte_2224
rename efage058 fte_2529
rename efage059 fte_3034
rename efage0510 fte_3539
rename efage0511 fte_4049
rename efage0512 fte_5064
rename efage0513 fte_over65 

label var fte_total "Total UGFTE"
label var fte_under25 "UGFTE Under 25"
label var fte_over25 "UGFTE Over 25"
label var fte_1819 "UGFTE enrl 18-19"
label var fte_2021 "UGFTE enrl 20-21"
label var fte_2224 "UGFTE 22-24"
label var fte_2529 "UGFTE 25-29"
label var fte_3034 "UGFTE 30-34"
label var fte_3539 "UGFTE 35-39"
label var fte_4049 "UGFTE 40-49"
label var fte_5064 "UGFTE 50-64"
label var fte_over65 "UGFTE over65"

//part-time
rename efage061 pt_total
rename efage062 pt_under25
rename efage067 pt_over25
rename efage064 pt_1819
rename efage065 pt_2021
rename efage066 pt_2224
rename efage068 pt_2529
rename efage069 pt_3034
rename efage0610 pt_3539
rename efage0611 pt_4049
rename efage0612 pt_5064
rename efage0613 pt_over65 

label var pt_total "Total UG Part-Time Enrollment"
label var pt_under25 "UG Part-Time Enrollment Under 25"
label var pt_over25 "UG Part-Time Enrollment Over 25"
label var pt_1819 "UG Part-Time enrl 18-19"
label var pt_2021 "UG Part-Time enrl 20-21"
label var pt_2224 "UG Part-Time enrl 22-24"
label var pt_2529 "UG Part-Time Enrollment 25-29"
label var pt_3034 "UG Part-Time Enrollment 30-34"
label var pt_3539 "UG Part-Time Enrollment 35-39"
label var pt_4049 "UG Part-Time Enrollment 40-49"
label var pt_5064 "UG Part-Time Enrollment 50-64"
label var pt_over65 "UG Part-Time Enrollment over65"

***save

save ${ddir}IPEDS_merged_fallenrl_age.dta, replace



/*******************************************************************************
 CODE SECTION: Completions: Age category, gender, attendance status and level of student 
 
AWLEVELC
	1	Award of less than 1 academic year
	3	Associate's degree
	5	Bachelor's degree
	7	Master's degree
	9	Doctor's degree
	10	Postbaccalaureate or Post-master's certificate
	11	Certificate of less than 12 weeks
	12	Certificate of at least 12 weeks but less than 1 year
	2	Certificate of at least 1 but less than 4 years
	
CSTOTLT-Grant Total 

CSUND18-Total Under 18
CS17_24-Total 18-24
CS25_39-Total 25-39
CSABV40-Total above 40
CSUNKN-Total age unknwon 

*******************************************************************************/

***append
use ${ddir}c2012c.dta, clear //only availiable post 2012
keep (unitid cstotlt awlevelc csund18 cs18_24 cs25_39 csabv40 csunkn)

gen year = 2012

local i 2013
	
	while `i' < 2022 {
		
	append using ${ddir}c`i'c.dta, keep (unitid cstotlt awlevelc csund18 cs18_24 cs25_39 csabv40 csunkn)
	
	replace year = `i' if year == .

	di `i'
	
	local i = `i' + 1
	
} 

***clean

//drop graduate award levels
drop if awlevel==7|awlevel==9|awlevel==10

//clean up names and var labels 
rename cstotlt dg_tot
rename csund18 dg_under18
rename cs18_24 dg_1824
rename cs25_39 dg_2539
rename csabv40 dg_abv40
rename csunkn dg_age_unkn 

label var dg_tot "Total number of students receiving degrees"
label var dg_under18 "Number of students under 18 receiving degrees"
label var dg_1824 "Number of students age 18 to 24 receiving degrees"
label var dg_2539 "Number of students age 25 to 39 receiving degrees"
label var dg_abv40 "Number of students age 40 or above receiving degrees"
label var dg_age_unkn "Number of students age unknown receiving degrees"

//rename awlevel 
tostring awlevelc, replace

replace awlevelc="_assoc" if awlevelc=="3"
replace awlevelc="_bach" if awlevelc=="5"
replace awlevelc="_cert1" if awlevelc=="1"
replace awlevelc="_cert1plus" if awlevelc=="2"
replace awlevelc="_cert12w" if awlevelc=="12"
replace awlevelc="_cert12wplus" if awlevelc=="11"

//reshape so there is one institution per year per row
reshape wide dg_tot dg_under18 dg_1824 dg_2539 dg_abv40 dg_age_unkn, i(unitid year) j(awlevelc, string)

***label 
label var dg_tot_assoc "Total Associates Degrees"
label var dg_under18_assoc "Associate's Degrees Awarded to People Under 18"
label var dg_1824_assoc "Associate's Degrees Awarded to People 18-24"
label var dg_2539_assoc "Associate's Degrees Awarded to People 25-39"
label var dg_abv40_assoc "Associate's Degrees Awarded to People Over 40"

label var dg_tot_bach "Total Bachelor's Degrees"
label var dg_under18_bach "Bachelor's Degrees Awarded to People Under 18"
label var dg_1824_bach "Bachelor's Degrees Awarded to People 18-24"
label var dg_2539_bach "Bachelor's Degrees Awarded to People 25-39"
label var dg_abv40_bach "Bachelor's Degrees Awarded to People Over 40"

***save

save ${ddir}IPEDS_merged_completion_age.dta, replace


/*******************************************************************************
 CODE SECTION: Finance - Public institutions - GASB 34/35
 
2003-2004 Fiscal Year - 2018-2019 Fiscal Year
F1C011 - Instruction - Current year total
F1C051 - Academic support - Current year total
F1C061 - Student services - Current year total

2001-2002 Fiscal Year-2002-2003 Fiscal Year
B013- Instruction 
B043-Academic support 
B063-Student Services 

*******************************************************************************/


***append

use ${ddir}f1999_f1a.dta, clear 

keep unitid f1c011 f1c051 f1c061

gen year = 1999 

local i 2000

	while `i' < 2022{
		
	append using ${ddir}f`i'_f1a.dta, keep (unitid f1c011 f1c051 f1c061)
	
	replace year = `i' if year == .

	local i = `i' + 1

} 

***label
label variable f1c011   "Instruction - Current year total"
label variable f1c051   "Academic support - Current year total"
label variable f1c061   "Student services - Current year total"

rename f1c011 inst_spending
rename f1c051 academic_support_spending
rename f1c061 student_services_spending 


*** Save Fall Enrollment - Student-to-Faculty File 

save ${ddir}IPEDS_merged_finance.dta, replace

/*******************************************************************************
 CODE SECTION: Instructional Staff/Salaries
	 EMPCOUNT-818-Number of full-time instructional faculty
	 ARANK-815-Academic rank and gender of faculty
		***1999, 2002-2021:*********************************** 
		label define label_arank 1 "Professor" 
		label define label_arank 2 "Associate professor", add 
		label define label_arank 3 "Assistant professor", add 
		label define label_arank 4 "Instructor", add 
		label define label_arank 5 "Lecturer", add 
		label define label_arank 6 "No academic rank", add 
		label define label_arank 7 "All faculty total", add 
		****2001*********************************************
		label define label_arank 1 "Professor, men" 
		label define label_arank 10 "Assistant professor, women", add 
		label define label_arank 11 "Instructor, women", add 
		label define label_arank 12 "Lecturer, women", add 
		label define label_arank 13 "No academic rank, women", add 
		label define label_arank 14 "Total women", add 
		label define label_arank 15 "Total faculty (men and women)", add 
		label define label_arank 2 "Associate professor, men", add 
		label define label_arank 3 "Assistant professor, men", add 
		label define label_arank 4 "Instructor, men", add 
		label define label_arank 5 "Lecturer, men", add 
		label define label_arank 6 "No academic rank, men", add 
		label define label_arank 7 "Total, men", add 
		label define label_arank 8 "Professor, women", add 
		label define label_arank 9 "Associate professor, women", add 

*******************************************************************************/

//These variables change a lot overtime so I clean years separately as needed 

***1999
use ${ddir}sal1999_is.dta, clear
drop x*
keep (unitid empcntt arank)
rename empcntt empcount 

//create a count of total employees by institution by rank 
collapse (sum) empcount, by(unitid arank)
reshape wide empcount, i(unitid) j(arank)

//put in zeros so I can calculate sums in each category 
forvalues i=1/7{
replace empcount`i'=0 if empcount`i'==.
}

//combine different ranks into smaller categories 
gen inst_staff_tot=empcount7 //total 
gen inst_staff_prof=empcount1+empcount2+empcount3 //faculty 
gen inst_staff_other_academic=empcount4+empcount5 //other academic
gen inst_staff_nonacademic=empcount6 //nonacademic 

g year=1999
keep unitid inst_staff_tot inst_staff_prof inst_staff_other_academic inst_staff_nonacademic year

save ${ddir}sal1999_is_clean.dta, replace

*no 2000 file is posted on IPEDS for this year  

***2001
use ${ddir}sal2001_is.dta, clear
keep (unitid empcount arank)

//create a count of total employees by institution by rank 
collapse (sum) empcount, by(unitid arank)
reshape wide empcount, i(unitid) j(arank)

//put in zeros so I can calculate sums in each category 
forvalues i=1/15{
replace empcount`i'=0 if empcount`i'==.
}

//combine different ranks into smaller categories 
gen inst_staff_tot=empcount15
gen inst_staff_prof=empcount1+empcount2+empcount3+empcount8 ///
+empcount9+empcount10
gen inst_staff_other_academic=empcount4+empcount5+empcount11+ ///
empcount12
gen inst_staff_nonacademic=empcount6+empcount13

keep unitid inst_staff_tot inst_staff_prof inst_staff_other_academic inst_staff_nonacademic

save ${ddir}sal2001_is_clean.dta, replace

***2002-2011

foreach year of numlist 2002/2011{
	
use ${ddir}sal`year'_is.dta, clear
keep (unitid empcntt arank)

//create a count of total employees by institution by rank 
collapse (sum) empcntt, by(unitid arank)
rename empcntt empcount
reshape wide empcount, i(unitid) j(arank)

//put in zeros so I can calculate sums in each category 
forvalues i=1/7{
replace empcount`i'=0 if empcount`i'==.
}

//combine different ranks into smaller categories 
gen inst_staff_tot=empcount7
gen inst_staff_prof=empcount1+empcount2+empcount3
gen inst_staff_other_academic=empcount4+empcount5
gen inst_staff_nonacademic=empcount6

keep unitid inst_staff_tot inst_staff_prof inst_staff_other_academic inst_staff_nonacademic

save ${ddir}sal`year'_is_clean.dta, replace

}

***2012-2021

foreach year of numlist 2012/2021{
use ${ddir}sal`year'_is.dta, clear
keep (unitid satotlt arank)

//create a count of total employees by institution by rank 
rename satotlt empcount
reshape wide empcount, i(unitid) j(arank)

//put in zeros so I can calculate sums in each category 
forvalues i=1/7{
replace empcount`i'=0 if empcount`i'==.
}

//combine different ranks into smaller categories 
gen inst_staff_tot=empcount7
gen inst_staff_prof=empcount1+empcount2+empcount3
gen inst_staff_other_academic=empcount4+empcount5
gen inst_staff_nonacademic=empcount6

keep unitid inst_staff_tot inst_staff_prof inst_staff_other_academic inst_staff_nonacademic

save ${ddir}sal`year'_is_clean.dta, replace
}

***append 

use ${ddir}sal2001_is_clean.dta, clear 

gen year = 2001

local i 2002
	
	while `i' < 2022 {
		
	append using ${ddir}sal`i'_is_clean.dta
	
	replace year = `i' if year == .

	di `i'
	
	local i = `i' + 1
	
} 

append using ${ddir}sal1999_is_clean

***label variables 

label var inst_staff_tot  "Total instructional staff"
label var inst_staff_prof "Instructional staff, professors"
label var inst_staff_other_academic "Instructional staff, lecturers and instructors"
label var inst_staff_nonacademic "Instructional staff, no academic rank"


***save
save ${ddir}IPEDS_merged_instructional_faculty.dta, replace



/********************************************************************************
CODE SECTION: State and County-Level Population, by age and race/ethnicity 

*c_ vars are county level, ex c_pop_under18 is county pop under 18
*st_ vars are state level, ex s_pop_under18 is state pop under18

Race code:
wh=white
hsp=hispanic 
bk=blakc
na=native american
as=asian 
********************************************************************************/


local full_data=0 //this section is slow, change to 0 after the first time 

if `full_data'==1 {

import delimited "${ddir}us.1990_2020.singleages.txt", stringcols(_all) clear 

**split fixed text into columns
gen year=substr(v1,1,4)
destring year, replace
drop if year<1999

gen stabbr=substr(v1,5,2)
gen st_fips=substr(v1,7,2)
gen county_fips=substr(v1,9,3) 
gen reg=substr(v1,12,2)
gen race=substr(v1,14,1)
gen origin=substr(v1,15,1)
gen sex=substr(v1,16,1)
gen age=substr(v1,17,2)
gen pop=substr(v1,19,8)
destring pop, replace

//drop region
drop reg 

//combine race and origin
	//NOTE: observation is counted as hispanic regardless of race indicated
replace race="5" if origin=="1"
drop origin

//sum male and female 
collapse(sum) pop, by(year stabbr st_fips county_fips race age)

//reshape age
reshape wide pop, i(year stabbr st_fips county_fips race) j(age) string 

//combine age categories

egen pop_total=rowtotal(pop00-pop85)

egen pop_under18=rowtotal(pop00 - pop17)

egen pop_1824=rowtotal(pop18 - pop24)

egen pop_2539=rowtotal(pop25 - pop39)

egen pop_abv40=rowtotal(pop40 - pop85)

egen pop_abv25=rowtotal(pop25 - pop85)

keep year stabbr st_fips county_fips race pop_total pop_under18 pop_1824 pop_2539 ///
pop_abv40 pop_abv25

//reshape race 
replace race="_wh" if race=="1"
replace race="_bk" if race=="2"
replace race="_na" if race=="3"
replace race="_as" if race=="4"
replace race="_hsp" if race=="5"

reshape wide pop_total pop_under18 pop_1824 pop_2539 pop_abv40 pop_abv25, i(year stabbr st_fips county_fips) j(race) string 

//add in total categories
egen pop_tot=rowtotal(pop_tot*)
egen pop_under18=rowtotal(pop_under18*)
egen pop_1824=rowtotal(pop_1824*)
egen pop_2539=rowtotal(pop_2539*)
egen pop_abv40=rowtotal(pop_abv40*)
egen pop_abv25=rowtotal(pop_abv25*)

save ${ddir}pop_county_level.dta, replace

collapse(sum) pop*, by (year stabbr)

rename pop* st_pop*

save ${ddir}pop_st_level.dta, replace

use ${ddir}pop_county_level.dta, clear

rename pop* c_pop*

merge m:1 stabbr year using ${ddir}pop_st_level.dta
drop _merge

save ${ddir}pop_merged.dta, replace

}

else use ${ddir}pop_merged.dta, clear

//gen county-level data set 

tostring(st_fips), replace
gen st_fips_correct=string(real(st_fips),"%02.0f")
tostring(county_fips), replace
gen county_fips_correct=string(real(county_fips),"%03.0f")
drop county_fips st_fips

gen county_fips=st_fips_correct+county_fips_correct
destring county_fips, replace 
rename st_fips_correct st_fips

*NOTE: This is only available through 2020. In data_cleaning, I fill in the 2020 values for 2021
save ${ddir}pop_merged_clean.dta, replace

/********************************************************************************
CODE SECTION: Median Income (State)

MEDIAN_INC_FRED-median household income in state 
********************************************************************************/

**FRED DATA (1999-2021, state-level only)
use ${ddir}med_inc_all.dta, clear 

//add year 
gen year=substr(datestr,1,4)
destring year, replace

//update names of format of vars 
gen stabbr=substr(series_id,9,2)
rename value med_inc_fred 
drop datestr daten series_id

save ${ddir}med_inc_all_clean.dta, replace

/********************************************************************************
CODE SECTION: Median Income (County)

SAIPE_C_INC-median household income in county
SAIPE_C_POV-percent of people of all ages in county living in poverty  
********************************************************************************/

***SAIPE Data (1999-2021) 

//update format and names of vars 
use ${ddir}c_saipe_data.dta, clear
replace fips=usubstr(fips, 2,.) if usubstr(fips,1,1) == "0"
rename county_fips county_fips1
egen county_fips=concat(fips county_fips1)
destring fips, replace
destring county_fips, replace 
drop county_fips1

save ${ddir}c_saipe_data_clean.dta, replace 


/********************************************************************************
CODE SECTION: Unemployment (1999-2021) (State)

FRED_UNEMPL0Y_RATE=percent of people in state who are unemployed (16 and over)

*The unemployment rate represents the number of unemployed as a percentage of the labor force. Labor force data are restricted to people 16 years of age and older, who currently reside in 1 of the 50 states or the District of Columbia, who do not reside in institutions (e.g., penal and mental facilities, homes for the aged), and who are not on active duty in the Armed Forces.

********************************************************************************/

**FRED DATA
use ${ddir}fred_unemploy_all.dta, clear
rename value fred_unemploy_rate

//update format and names of vars 
gen year=substr(datestr,1,4)
destring year, replace
drop datestr daten series_id
rename st_fips fips

save ${ddir}fred_unemploy_all_clean.dta, replace

/********************************************************************************
CODE SECTION: Unemployment (1999-2021) (County)

BLS_UNEMPLOY-% of people in county who are employed 
********************************************************************************/ 

***BLS Data (County-level: 1999-2021)

use ${ddir}bls_unemploy_all.dta, clear
destring year, replace 
drop if year==. 

//update format and names of vars 
rename  per_unemployed bls_unemploy
replace bls_unemploy="0" if bls_unemploy=="N.A."
destring bls_unemploy, replace 
replace bls_unemploy=. if bls_unemploy==0

save ${ddir}bls_unemploy_all_clean.dta, replace


/********************************************************************************
CODE SECTION: Region Crosswalk
********************************************************************************/
 
//update format and names of vars 
import excel ${ddir}state_region.xlsx,firstrow clear
rename Stabbr stabbr
rename Region region 

save ${ddir}state_region, replace

/*******************************************************************************
 CODE SECTION: Merge Files
*******************************************************************************/

use ${ddir}inst_merged.dta,clear
drop _merge

* Fall Enrollment Age
merge 1:1 unitid year using ${ddir}IPEDS_merged_fallenrl_age.dta //unmatched are even yr non-reporting inst
drop _merge

* Student Charges
merge 1:1 unitid year using ${ddir}IPEDS_merged_stuchgsay.dta //unmatched nonpublic 
drop _merge

* Finance 
merge 1:1 unitid year using ${ddir}IPEDS_merged_finance.dta
drop _merge

*Completion Age
merge 1:1 unitid year using ${ddir}IPEDS_merged_completion_age.dta
drop _merge

*Instructional Staff 
merge 1:1 unitid year using ${ddir}IPEDS_merged_instructional_faculty.dta
drop _merge

*State Population data 

merge m:1 stabbr year using ${ddir}pop_st_level.dta
drop _merge

*County Population data

merge m:1 stabbr year county_fips using ${ddir}pop_merged_clean.dta
drop _merge


*State Median Income: FRED

merge m:1 stabbr year using ${ddir}med_inc_all_clean.dta
drop _merge

*County Median Income/Unemployment: SAIPE
merge m:1 fips year county_fips using ${ddir}c_saipe_data_clean.dta
drop _merge
drop if unitid==.


*State Unemployment: FRED 
 
merge m:1 fips year using ${ddir}fred_unemploy_all_clean.dta
drop _merge


*County Unemployment: BLS

merge m:1 fips county_fips year using ${ddir}bls_unemploy_all_clean.dta

*region 
drop _merge
merge m:1 stabbr using ${ddir}state_region.dta 


//Fill-in Enrollment Data for non-reporting years 
********************************************************************************
//NOTE: IPEDS only requires insts to report enrollment by age in even years 

gen odd=mod(year,2)
sort unitid year

local age_cat fte_total fte_under25 fte_2224 fte_over25 fte_2529 fte_3034 fte_3539 fte_4049 fte_5064 fte_over65  ug_total  ug_over25 ug_under25 ug_18 ug_2224  ug_2529 ug_3034 ug_3539 ug_4049 ug_5064 ug_over65 pt_total pt_under25 pt_2224 pt_over25 pt_2529 pt_3034 pt_3539 pt_4049 pt_5064 pt_over65 ug_1819 ug_2021 pt_1819 pt_2021 fte_1819 fte_2021


foreach myvar of local age_cat {
	
	 by unitid: gen c_`myvar'=`myvar'
	 by unitid: replace c_`myvar'=`myvar'[_n-1] if odd==0 & missing(`myvar') | `myvar'==0
}

**gen a combined 18-21 enrollment measure
g c_ug_1821=c_ug_18+c_ug_2021


save ${adir}IPEDS_merged.dta, replace


********************************************************************************
//Combine Ivy Tech
********************************************************************************
/*Ivy tech is a large treated institutions that reported branch campuses separately prior to 2012
and then reported all campuses together post 2012. So that this doesn't mess with averages, 
I combine early years for ivy tech here */

//step one: create a dataset of combined enrollment and overall completions values by year 

use ${adir}IPEDS_merged.dta, clear 
keep if year<2012 & stabbr=="IN" 
keep if unitid==150978|unitid==150987|unitid==150996|unitid==151005|unitid==151023|unitid==151041| unitid== 151050|unitid==151069|unitid== 151078| unitid== 151087| unitid==151096


collapse (sum) c_*, by(year)

gen unitid=150987 //unitid in later years
gen instnm="Ivy Tech Community College"

save ${ddir}ivy_tech.dta, replace  

//step two: create a dataset of other covariates using the information for main campus-central indiana, which has the same unitid as the combined ivy tech observation post 2012

use ${adir}IPEDS_merged.dta, clear 
keep if year<2012 & stabbr=="IN" 
keep if unitid==150987

drop c_* 

save ${ddir}ivy_tech2.dta, replace 

//step three, merge two ivy tech datasets together
drop _merge 
merge 1:1 unitid year using ${ddir}ivy_tech.dta

save ${ddir}ivy_tech3.dta, replace 

//step four, drop out other ivy tech observations and add in the merged data set to the full ds
use ${adir}IPEDS_merged.dta, clear

drop if unitid==150978| unitid==150996|unitid==151005|unitid==151023|unitid==151041| unitid==151050|unitid==151069|unitid== 151078| unitid== 151087| unitid==151096
drop if unitid==150987 & year<2012

append using ${ddir}ivy_tech3.dta 

********************************************************************************
//Save Merged file
********************************************************************************
save ${adir}IPEDS_merged.dta, replace






