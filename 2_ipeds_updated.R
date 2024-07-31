################################################################################
##
## <PROJ> Branch MSA
## <FILE> ipeds.r
## <AUTH> Will Doyle and Coral Flanagan
## <INIT> 2015-05-27
## <REV> 2022-03-29
## <PURPOSE> Download multiple years of ipeds data for branch campus project
################################################################################


## CODE

## Code modified from <ipeds_combine.r>:

## https://gist.github.com/btskinner/f42c87507169d0ba773c

##Libraries
library(tidyverse)
library(crosswalkr)
library(here)


## load functions
source(here("scripts","functions.r"))

rddir<-paste0(here("data","raw"),"/")


##NOTE: the way the code is written now, the values from 2012 and 2011 are filling for subsequent years

## =============================================================================
## BUILD DATASETS: 2013-2019
## =============================================================================

#for (i in c("2013","2014","2015","2016","2017","2018","2019","2020")) 
  
for (i in c("2015","2020")) {

years<-i

## IPEDS institutional characteristics-directory (using HD files)
## =============================================================================

filenames<-paste0('HD',i,'.zip')
var <- c('unitid','instnm','city','stabbr','control','sector','carnegie','c18ipug','c15basic','obereg', 'ugoffer','latitude','longitud','addr','zip',
         'countycd','csa', 'deggrant','preddeg','instcat', 'opeid', 'tribal', 'hbcu', 'locale', 'instsize', 'iclevel', 'pset4flg')
hd_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var, years=years)
hd_df<-hd_df%>%select(-year)

##IPEDS institutional characteristics-educational offerings
## =============================================================================

filenames<-paste0('IC',i,'.zip')
var <- c('unitid','distnced')
ic_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var,years=years)
ic_df<-ic_df%>%select(-year)

## =============================================================================
##IPEDS graduation Rates
  #grtype:
  # 8 bachelors adjusted cohort (4-yr institution)
  # 9 bachelors completers within 150% of time (4-yr institution)
  # 20	Other degree/certif-seeking subcohort (4-yr institution) Adjusted cohort (revised cohort minus exclusions)
  # 21	Other degree/certif-seeking subcohort (4-yr institution) Completers within 150% of normal time total
  # 29 Degree/certif-seeking students ( 2-yr institution) Adjusted cohort (revised cohort minus exclusions)
  # 30 Degree/certif-seeking students ( 2-yr institution) Completers within 150% of normal time total 
## =============================================================================

filenames<-paste0('GR',i,'.zip')
var <- c('unitid','grtotlt','grtype')
gr_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var,years=years)

gr_df<-gr_df%>%
  filter(grtype==8|grtype==9|grtype==20|grtype==21|grtype==29|grtype==30)%>%
  mutate(grad_type=ifelse(grtype==8, "bachelor_cohort_4",
                   ifelse(grtype==9, "bachelor_completers_4",
                   ifelse(grtype==20, "degree_cohort_4",
                   ifelse(grtype==21, "degree_completers_4",
                   ifelse(grtype==29, "degree_cohort_2",
                   ifelse(grtype==30, "degree_completers_2", "na")))))))
           
  
gr_df<-gr_df%>%
  pivot_wider(id_cols=c("unitid", "year"), 
              names_from= grad_type,
              values_from= grtotlt)

gr_df[is.na(gr_df)]<-0

gr_df<-gr_df%>%
  mutate(bach_grad_rate=bachelor_completers_4/bachelor_cohort_4)%>%
  mutate(grad_rate_4=degree_completers_4/degree_cohort_4)%>%
  mutate(grad_rate_2=degree_completers_2/degree_cohort_2)

gr_df[is.na(gr_df)]<-0
gr_df<-gr_df%>%select(-year)


## IPEDS enrollments (using EFIA files)
## =============================================================================

filenames <-paste0('EFIA',i,'.zip')
var <- c('unitid','fteug')
efia_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars= var ,years=years)
efia_df<-efia_df%>%select(-year)

##IPEDS institutional characteristics (using IC files)##
## =============================================================================

filenames<-paste0('IC',i,'_AY','.zip')
var <- c('unitid','tuition1')
ic_ay_df<- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var,years=years)
ic_ay_df<-ic_ay_df%>%select(-year)
 
# ## =============================================================================
##IPEDS Degrees characteristics (using IC files)##
# ## Degrees awarded
# # ## AWlevel codes
# #   3	Associate's degree
# # 5	Bachelor's degree
# # 7	Master's degree
# # 9	Doctor's degree
# # 10	Postbaccalaureate or Post-master's certificate
# # 1	Award of less than 1 academic year
# # 2	Award of at least 1 but less than 4 academic years
# ## =============================================================================

filenames<-paste0('C',i,'_C.zip')
var<-c('unitid','awlevelc','cstotlt')
comp_df<-build.dataset.ipeds(filenames=filenames, datadir = rddir, vars= var,years=years)
comp_df<-comp_df%>%
  pivot_wider(id_cols=c("unitid","year"),
               names_from = awlevelc,
               values_from =cstotlt )
 names(comp_df)[3:9]<-c("Bachelors",
                        "Masters",
                        "PhD",
                        "Cert> 1",
                        "Postbac",
                       "Associates",
                        "Cert<1")
comp_df<-comp_df%>%
   mutate_all(replace_na,0)

comp_df<-comp_df%>%select(-year)

##IPEDS admissions##
## =============================================================================

filenames<-paste0('ADM',2015,'.zip')
var <- c('unitid','admssn','applcn')
adm_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var, years=years)

adm_df<-adm_df%>%
  select(unitid,acceptance_rate)

# note: tried to figure out open access status for later years using admissions reqs 
#but almost all schools require students to submit these things even if they are open access
  # #adm_df<-adm_df%>%
  # mutate(acceptance_rate=admssn/applcn)%>%
  #   mutate(openadmp=ifelse(admcon1==3 & admcon2==3 & admcon3==3 & admcon4==3 &
  #                            admcon5==3 & admcon6==3 & admcon7==3 & admcon8==3 & admcon9==3, 1, 0))


## =============================================================================
## MERGE DATASETS
## =============================================================================

inst<-
  hd_df%>%
  left_join(efia_df, by="unitid")%>%
  left_join(ic_df, by="unitid")%>%
  left_join(gr_df, by="unitid")%>%
  left_join(ic_ay_df, by="unitid")%>%
  left_join(comp_df, by="unitid")%>%
  left_join(adm_df, by="unitid")


## =============================================================================
## Some misc cleanup
## =============================================================================

inst<-inst%>%left_join(stcrosswalk,by="stabbr") %>%
  rename(name = stname, region = cenreg)

inst$year<-i

## =============================================================================
## OUTPUT FINAL DATASET
## =============================================================================

write_csv(inst,file=here("data","raw","ipeds", paste0("ipeds_",i,".csv")))
}

## =============================================================================
## BUILD DATASETS: 2010
## =============================================================================

for (i in c("2010")) {
  #removing completions because they start in 2012
  
  years<-i
  
  ## IPEDS institutional characteristics-directory (using HD files)
  ## =============================================================================
  
  filenames<-paste0('HD',i,'.zip')
  var <- c('unitid','instnm','city','stabbr','control','sector','carnegie','c18ipug','c15basic','obereg', 'ugoffer','latitude','longitud','addr','zip',
           'countycd','csa', 'deggrant','preddeg','instcat', 'opeid', 'tribal', 'hbcu', 'locale', 'instsize', 'iclevel', 'pset4flg')
  hd_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var, years=years)
  hd_df<-hd_df%>%select(-year)
  
  
  ## IPEDS enrollments (using EFIA files)
  ## =============================================================================
  
  filenames <-paste0('EFIA',i,'.zip')
  var <- c('unitid','fteug')
  efia_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars= var ,years=years)
  efia_df<-efia_df%>%select(-year)
  
  ## =============================================================================
  ##IPEDS graduation Rates
  #grtype:
  # 8 bachelors adjusted cohort (4-yr institution)
  # 9 bachelors completers within 150% of time (4-yr institution)
  # 20	Other degree/certif-seeking subcohort (4-yr institution) Adjusted cohort (revised cohort minus exclusions)
  # 21	Other degree/certif-seeking subcohort (4-yr institution) Completers within 150% of normal time total
  # 29 Degree/certif-seeking students ( 2-yr institution) Adjusted cohort (revised cohort minus exclusions)
  # 30 Degree/certif-seeking students ( 2-yr institution) Completers within 150% of normal time total 
  ## =============================================================================
  
  filenames<-paste0('GR',i,'.zip')
  var <- c('unitid','grtotlt','grtype')
  gr_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var,years=years)
  
  gr_df<-gr_df%>%
    filter(grtype==8|grtype==9|grtype==20|grtype==21|grtype==29|grtype==30)%>%
    mutate(grad_type=ifelse(grtype==8, "bachelor_cohort_4",
                            ifelse(grtype==9, "bachelor_completers_4",
                                   ifelse(grtype==20, "degree_cohort_4",
                                          ifelse(grtype==21, "degree_completers_4",
                                                 ifelse(grtype==29, "degree_cohort_2",
                                                        ifelse(grtype==30, "degree_completers_2", "na")))))))
  
  
  gr_df<-gr_df%>%
    pivot_wider(id_cols=c("unitid", "year"), 
                names_from= grad_type,
                values_from= grtotlt)
  
  gr_df[is.na(gr_df)]<-0
  
  gr_df<-gr_df%>%
    mutate(bach_grad_rate=bachelor_completers_4/bachelor_cohort_4)%>%
    mutate(grad_rate_4=degree_completers_4/degree_cohort_4)%>%
    mutate(grad_rate_2=degree_completers_2/degree_cohort_2)
  
  gr_df[is.na(gr_df)]<-0
  gr_df<-gr_df%>%select(-year)
  
  ##IPEDS institutional characteristics (using IC files)##
  ## =============================================================================
  #something weird was happening with Ben's code here where the variables were shifting
  #Downloaded these files by hand
  
  file_path <- here("data", "raw", paste0("ic",i,"_ay_rv.csv"))
  
  ic_ay_df<- read.csv(file_path, header=FALSE)
  
  ic_ay_df<-ic_ay_df%>%
    rename(unitid1=V1)%>%
    rename(tuition1=V3)
  
  ic_ay_df<-ic_ay_df%>%select(tuition1, unitid1)
  ic_ay_df <- ic_ay_df[-1,]
  
  ic_ay_df<- ic_ay_df%>%mutate(unitid=as.numeric(unitid1))%>%
    select(-unitid1)
  
  ##IPEDS admissions##
  ## =============================================================================

  filenames<-paste0('IC',i,'.zip')
  var <- c('unitid','admssn','applcn','openadmp')
  adm_df <- build.dataset.ipeds(filenames=filenames, datadir = rddir, vars = var, years=years)

  adm_df<-adm_df%>%
    mutate(applcn=as.numeric(applcn))%>%
    mutate(admssn=as.numeric(admssn))%>%
    mutate(acceptance_rate=admssn/applcn)%>%
    select(unitid,acceptance_rate, openadmp)
  
  ## =============================================================================
  ## MERGE DATASETS
  ## =============================================================================
  
  inst<-
    hd_df%>%
    left_join(efia_df, by="unitid")%>%
    left_join(ic_df, by="unitid")%>% #note this files prior year value 
    left_join(gr_df, by="unitid")%>%
    left_join(ic_ay_df, by="unitid")%>%
    left_join(comp_df,by="unitid")%>%
    left_join(adm_df,by="unitid")#note this files prior year value 
  
  
  ## =============================================================================
  ## Some misc cleanup
  ## =============================================================================
  
  inst<-inst%>%left_join(stcrosswalk,by="stabbr") %>%
    rename(name = stname, region = cenreg)
  
  inst$year<-i
  
  
  
  ## =============================================================================
  ## OUTPUT FINAL DATASET
  ## =============================================================================
  
  write_csv(inst,file=here("data","raw","ipeds", paste0("ipeds_",i,".csv")))
}


## =============================================================================
## END
################################################################################












