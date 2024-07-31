################################################################################
##
## <PROJ> Covid Recovery
## <FILE> covid_recovery_data.r
## <AUTH> Will Doyle and Coral Flanagan 
## <INIT> 2022-02-22
################################################################################

## =============================================================================
## PURPOSE
## =============================================================================

## The purpose of this file is create a cleaned and updated version of the of 
##the shefo.dta dataset with information for all variables from 1984-2020

## =============================================================================
## CODE
## =============================================================================
  ## set wd to covid_recovery/scripts##

##Libraries
library(tidyverse)
library(tidycensus)
library(crosswalkr)
library(datasets)
library(here)
library(dplyr)
library(stringr)
library(readxl)
library(sf)
library(tidyquant)
library(forcats)
library(survival)
library(haven)
library(tigris)
library(datasets)
options(tigris_class = "sf")
library(tabulizer)
library(shiny)
library(miniUI)
library(janitor)

rddir<-"../data/raw/"

addir<-"../data/cleaned/"

## =============================================================================
## Create List of State Names
## =============================================================================

##list 1 
#source: https://worldpopulationreview.com/states/state-abbreviations

df_states<-read_csv(here("data","raw","csvDATA.csv"))%>%
  select(-Abbrev)%>%
  rename(state=State)%>%
  rename(code=Code)


##list 2

data(stcrosswalk)
state_list<-as.character(stcrosswalk$stabbr)[1:51] ## 50 states and DC
state_list<-state_list[state_list!="DC"] 
state_abbrevs<-state_list
states<-states%>%select(state,name)%>%filter(state%in%state_list)

## =============================================================================
## Load SHEFO Data (1984-2015)
## =============================================================================

#purpose:load in shefo.dta as a foundation (dataset from prior project)
#source: sent via email by Will 

df_shefo<-read_dta(here("data","raw","shefo.dta"))%>%
  select(-region)

#The row Alaska 2014 and 10 others were duplicated for some reason
df_shefo<-unique(df_shefo)

#SHEF data dictionary: https://shef.sheeo.org/data-definitions/

## =============================================================================
## Add in SHEEO Grapevine Data 1984-2020
## =============================================================================

##add in tax appropriations from SHEEO Grapevine
##source: https://shef.sheeo.org/grapevine/
  #note:  Historical data are available back to 1961 in PDF format on the Illinois State University website
  #https://education.illinoisstate.edu/grapevine/historical/

df_grpvn<-read_excel(here("data","raw","SHEEO_Grapevine_FY22_Data_Download.xlsx"),skip=16)

##rename variables so easier to work with 
df_grpvn<-df_grpvn%>%
  clean_names()%>%
  rename(fy=fiscal_year)%>%
  select(-region)

##merge df_shefo to sf_grpvn, limit years to 1984-2020
full_df<-merge(df_shefo,df_grpvn,all=TRUE)%>%
  filter(fy<2022 & fy>1983)

## =============================================================================
## CPI 2016-2020
## =============================================================================

#source: https://fred.stlouisfed.org/series/CPIAUCSL#0
#click "edit graph" to select annual data 

df_cpi<-read_csv(here("data","raw","CPIAUCSL.csv"))%>%
  mutate(fy=substr(DATE,1,4))%>%
  rename(cpi=CPIAUCSL)%>%
  select(-DATE)

full_df<-merge(full_df,df_cpi)

##create cpi ratio to adjust to 2020 dollars 
  #annual cpi for 2020 is 258.83825
full_df<-full_df%>%
  mutate(cpi=parse_number(cpi))%>%
  mutate(cpi_20=258.83825)%>%
  mutate(cpi_ratio=cpi_20/cpi)

## =============================================================================
## IPEDS data
## =============================================================================
  #Purpose: 
    #add fteug, by sector and control, 1984-2020
    #add pct in publics, 1984-2020
    #add average 4-year tuition, 2016-2020

df_ipeds<-read_csv(here("data","raw","ipeds_states.csv"))%>%
  select(-stabbr)%>%
  rename(state=stname)

full_df<-full_df%>%
  left_join(df_ipeds)%>%
  select(-pct_public)%>%
  rename(pct_public=pct_public1)

#cpi adjust tuition
full_df<-full_df%>%
  mutate(tuition_cpi_late=average_tuition*cpi_ratio)


##replace 
full_df$tuition_cpi[full_df$fy%in%2016:2020]<-full_df$tuition_cpi_late[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-tuition_cpi_late)


#QUESTION: these variables do not match up
  # I think it must be because of institution type, 2-year identification?



  
## =============================================================================
## Update Shefo Variables for 2016-2020
## =============================================================================

  #Note: some code borrowed from recovery.Rmd

## =============================================================================
## HS/College attainment 2016-2020 
## =============================================================================

#source: use get_acs to download data
  #according to recovery draft=
    #HS attainment= % of the adult population (25+) whose highest level of  attainment is  a high school diploma
    #College attainment=% of the population that has attained a bachelors degree (or higher)
#Add 2020 data on March 27 

##2016-2019##
educ_vars_overall<-NULL

for (year in 2016:2020){
  
  educ_vars<-get_acs(geography = "state",
                     table="B15003",
                     year=year,
                     cache_table=TRUE)
  
  ## Spread, so that each level of education gets its own column
  educ_vars<-educ_vars%>%
    select(GEOID,NAME,variable,estimate)%>%
    spread(key=variable,value = estimate)
  
  ## rename to be all lower case 
  names(educ_vars)<-str_to_lower(names(educ_vars))
  
  ## Calculate prop with at least HS diploma for every county
  educ_vars<-educ_vars%>%
    mutate(highschoolattainment_late=(
      b15003_017+
        b15003_018+
        b15003_019+
        b15003_020+
        b15003_021)/b15003_001)
  
  ## Calculate prop with at least bachelor's for every county
  educ_vars<-educ_vars%>%
    mutate(collegeattainment_late=(b15003_022+
                                     b15003_023+
                                     b15003_024+
                                     b15003_025)/b15003_001)
  
  ## simplify to just proportion
  educ_vars<-educ_vars%>%
    select(name,highschoolattainment_late,collegeattainment_late)
  
  educ_vars$fy<-year
  
  educ_vars_overall<-bind_rows(educ_vars_overall,educ_vars)
}

educ_vars_overall<-educ_vars_overall%>%
  rename(state=name)

full_df<-left_join(full_df,educ_vars_overall,by=c("fy","state"))

full_df<-full_df%>%
  mutate(highschoolattainment=ifelse(fy==2016|fy==2017|fy==2018|fy==2019|fy==2020,
                                     highschoolattainment_late, highschoolattainment))%>%
  mutate(collegeattainment=ifelse(fy==2016|fy==2017|fy==2018|fy==2019|fy==2020,
                                    collegeattainment_late, collegeattainment))%>%
  filter(state!="U.S.")%>%
  select(-highschoolattainment_late, -collegeattainment_late)




## =============================================================================
## Median Family Income 
## =============================================================================

#source: https://fred.stlouisfed.org/series/MEHOINUSCAA646N

#recovery code
     med_inc1<-NULL
     for (st in state_list){
        st_med_inc<-tq_get(paste0("MEHOINUS",st,"A672N"),
                              get="economic.data",from="2016-01-01",to="2020-07-01",period="annual")%>%
             tq_transmute(select=price,mutate_fun =to.yearly)
           
           st_med_inc$state<-st
           st_med_inc$year<-year(st_med_inc$date)
           st_med_inc$med_inc1<-st_med_inc$price
           st_med_inc<-st_med_inc%>%select(state,year,med_inc1)
           
           med_inc1<-bind_rows(med_inc1,st_med_inc)
     }

##merge with full_df

##make sure variables have the same names 
med_inc1<-med_inc1%>%
  rename(code=state)%>%
  rename(fy=year)
         
med_inc1<-left_join(med_inc1,df_states,by="code")%>%
  select(-code)

full_df<-left_join(full_df,med_inc1, by=c("state","fy"))
  

full_df$med_inc[full_df$fy%in%2016:2020]<-full_df$med_inc1[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-med_inc1)

## =============================================================================
## Unemployment 
## =============================================================================


unemploy<-NULL
for (st in state_abbrevs){
  st_unemploy<-tq_get(paste0(st,"UR"),
                      get="economic.data",from="2016-01-01",to="2020-07-01",period="annual")%>%
    tq_transmute(select=price,mutate_fun =to.yearly)
  
  st_unemploy$state<-st
  st_unemploy$year<-year(st_unemploy$date)
  st_unemploy$unemploy<-st_unemploy$price
  st_unemploy<-st_unemploy%>%select(state,year,unemploy)
  
  unemploy<-bind_rows(unemploy,st_unemploy)
}

##merge with full_df

##make sure variables have the same names 
unemploy<-unemploy%>%
  rename(code=state)%>%
  rename(fy=year)%>%
  rename(unemploy1=unemploy)

unemploy<-left_join(unemploy,df_states)%>%
  select(-code)

full_df<-left_join(full_df,unemploy, by=c("state","fy"))


full_df$unemploy[full_df$fy%in%2016:2020]<-full_df$unemploy1[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-unemploy1)


## =============================================================================
## Percent of Population over 65
## =============================================================================

#could not get this code from recovery.Rmd to work 
  #if(file.exists("../data/raw/seer.Rdata")==FALSE){
  #download.file("https://seer.cancer.gov/popdata/yr1990_2020.19ages/us.1990_2020.19ages.txt.gz",destfile = "../data/raw/us_age_data.gz")

##So I downloaded us.1990_2020.19ages.txt.gz via  :https://seer.cancer.gov/popdata/download.html 
  #and saved it as "us_age_data.gz"

system("gunzip -c  ../data/raw/us_age_data.gz > ../data/raw/age_data.txt")
seer<-read_fwf("../data/raw/age_data.txt",
               fwf_cols(year=4,
                        state=2,
                        st_fips=2,
                        county_fips=3,
                        reg=2,
                        race=1,
                        origin=1,
                        sex=1,
                        age=2,
                        pop=8))

save(seer,file = "../data/raw/seer.Rdata")               

load("../data/raw/seer.Rdata")




## Organizing the SEER Data

seer_a<-seer%>%
  mutate(pop=as.numeric(pop))%>% 
  group_by(year,state)%>%
  mutate(state_pop=sum(pop))%>%
  group_by(year,state,age)%>%
  mutate(total_pop=sum(pop,na.rm=TRUE))%>%
  summarize_at(.vars = c("state_pop","total_pop"),.funs = mean)%>% ## Repeated across ages
  mutate(pct_pop=total_pop/state_pop)%>% 
  select(year,state,total_pop,state_pop,age,pct_pop)

## Percent values
seer_b<-seer_a%>%
  mutate(age=as.numeric(age))%>%
  filter(age==5|age>=14)%>%
  mutate(pop_group=ifelse(age==5,"pct_pop2024","pct_pop65p"))%>%
  group_by(state,year,pop_group)%>%
  summarize(pct_group=sum(pct_pop))%>%
  select(year,state,pop_group,pct_group)%>%
  spread(key=pop_group,value=pct_group)%>%
  rename(code=state,
         fy=year)

seer_c<-seer_a%>%
  filter(as.character(age)=="05")%>%
  spread(key=age,value=total_pop)%>%
  mutate(pop2024=`05`)%>%
  select(year,state,pop2024)%>%
  rename(fy=year)%>%
  rename(code=state)%>%
  ungroup()

seer_all<-left_join(seer_b,seer_c)%>%
  left_join(df_states)%>%
  select(-code)%>%
  filter(year>2015)%>%
  filter(code!="DC")%>%
  select(-pct_pop2024)%>%
  rename(pct_pop65p_late=pct_pop65p)

full_df<-left_join(full_df,seer_all)

full_df$pct_pop65p[full_df$fy%in%2016:2020]<-full_df$pct_pop65p_late[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-pct_pop65p_late)

## =============================================================================
## GINI Coefficient 
## =============================================================================

##2016-2019##

state_gini_overall<-NULL

for (year in 2016:2020){
  
  state_gini<-get_acs(geography="state",
                      table ="B19083",
                      year=year)
  state_gini<-state_gini%>%
    select(NAME,estimate)%>%
    rename(state=NAME,gini_late=estimate)
  
  state_gini$fy<-year
  
  state_gini_overall<-bind_rows(state_gini_overall,state_gini)
  
}

full_df<-left_join(full_df,state_gini_overall,by=c("fy","state"))

full_df$gini[full_df$fy%in%2016:2020]<-full_df$gini_late[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-gini_late)

##2020##
#WAIT For data release on March 27

## =============================================================================
## NASSGAP
## =============================================================================

# var is Real Total Undergraduate Aid, cpi adjusted
# Recovery paper description: "total state student financial aid per full time equivalent student undergraduate"

#Could not extract data from pdfs, I created an excel sheet with this data by hand 
  #download data/share folder from github to access 
  #NOTE1: NASSGAP differentiates between South Carolina Commission on Higher Education and South Carolina Tuition Grants Commission. I combined them.
  #NOTE2: I included only ug aid not uncategorized aid. Some states have only uncategorized aid (Wyoming, New Hampshir)

#Sources: 
  #2020:not available yet
  #2019: https://www.nassgapsurvey.com/survey_reports/2019-2020-51st.pdf
  #2018: https://www.nassgapsurvey.com/survey_reports/2018-2019-50th.pdf
  #2017: https://www.nassgapsurvey.com/survey_reports/2017-2018-49th.pdf
  #2016: https://www.nassgapsurvey.com/survey_reports/2016-2017-48th.pdf


df_ngsp<-read_xlsx(here("data","share","nassgap_total_ug.xlsx"))

full_df<-left_join(full_df, df_ngsp)%>%
  mutate(total_ug_aid_fte_late=total_ug_aid/fteug_state)%>%
  mutate(total_ug_aid_fte_cpi_late=total_ug_aid_fte_late*cpi_ratio)

full_df$total_ug_aid_fte_cpi[full_df$fy%in%2016:2020]<-full_df$total_ug_aid_fte_cpi_late[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-total_ug_aid,-total_ug_aid_fte_late, -total_ug_aid_fte_cpi_late)

## =============================================================================
## Institutional Ideology
## =============================================================================
  #Source: //americanlegislatures.com/data/

df_idgy<-read_dta(here("data","raw","shor mccarty 1993-2018 state aggregate data July 2020 release.dta"))

df_idgy<-df_idgy%>%
  select(sen_chamber,st, year)%>%
  rename(fy=year)%>%
  rename(code=st)

df_idgy<-df_idgy%>%
  left_join(df_states)%>%
  select(-code)

full_df<-left_join(full_df,df_idgy)

##HI and Iowa are missing data on this one?

#QUESTION: Why isnt sen_chamber showing up?

## =============================================================================
## Educational Appropriations CPI
## =============================================================================

#source:https://shef.sheeo.org/data-downloads/

df_shef<-read_xlsx(here("data","raw","SHEEO_SHEF_FY20_Report_Data.xlsx"), sheet =2)%>%
  clean_names()

df_shef<-df_shef%>%
  select(state_tax_appropriations, fy, state)

full_df<-left_join(full_df, df_shef)%>%
  mutate(ed_app_pop=state_tax_appropriations/pop2024)

full_df<-full_df%>%
  mutate(ed_app_cpi_late=ed_app_pop*cpi_ratio)

full_df$ed_app_cpi[full_df$fy%in%2016:2020]<-full_df$ed_app_cpi_late[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-ed_app_cpi_late)

## =============================================================================
## Proportion Dem and Gov Party 
## =============================================================================
  #csv created using ncsl.R
  #download data/share file from github to access 
#var definition from recovery draft: proportion of the state legislature that is from the Democratic party

#load saved csv 

leg_control_all<-read_csv(here("data","share","legcontrol.csv"))%>%
  mutate(gov_democrat1=ifelse(gov_party=="Dem", 1, 0))%>%
  select(-gov_party)


##join legcontrol_all with full_df 

full_df<-left_join(full_df,leg_control_all)

full_df$prop_all_dem[full_df$fy%in%2016:2020]<-full_df$prop_all_dem_late[full_df$fy%in%2016:2020]
full_df$gov_democrat[full_df$fy%in%2016:2020]<-full_df$gov_democrat1[full_df$fy%in%2016:2020]

full_df<-full_df%>%
  select(-gov_democrat1,-prop_all_dem_late)


## =============================================================================
## Final Clean up
## =============================================================================

full_df<-full_df%>%
  select(-board,-code)%>%
  filter(state!="Washington DC")

##two gov_democrat rows for these states in original shefo.dta dataset
  #replace with correct code
full_df<-full_df[!(full_df$state=="Illinois"&full_df$gov_democrat==1 & full_df$fy==2015),]
full_df<-full_df[!(full_df$state=="Kentucky" & full_df$gov_democrat==0 & full_df$fy==2015),]

full_df<-full_df%>%
  select(-cpi_20, -average_tuition) 

## =============================================================================
## OUTPUT FINAL DATASET AS .CSV
## =============================================================================


write_csv(full_df, file = paste0(addir, 'covid_recovery.csv'))


## =============================================================================
## END
################################################################################












  
  
  

  

