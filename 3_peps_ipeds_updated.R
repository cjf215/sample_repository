################################################################################
##Goal: Merge Ipeps and Peps Data
#This is a second attempt using OPEIDs that do not eliminate leading 0s, 
#which lead to matching issues previously 
################################################################################

library(tidyverse)
library(tidygeocoder)
library(here)
library(utf8)
library(fastLink)
library(dplyr)
library(fuzzyjoin)
library(stringi)
library(stringr)
library(readr)
library(writexl)
library(readxl)

setwd("/Users/coralflanagan1/Desktop/projects/branch_campus/scripts")

################################################################################
#Read in and merge PEPS and IPEDS Data by Year
################################################################################

for (i in c("2010", "2015", "2020")) {
  
  #Read in PEPS Data 
  ################################################################################
  
  
  peps<- read_fwf(here("data","raw","peps", paste0("SCHFILE_",i,".TXT")),
                  skip = 1,
                  fwf_widths(
                    c(2, 8, 1, 70, 70, 35, 35, 25, 2, 3, 25, 14, 25, 1),
                    col_names = c(
                      "record_type",
                      "opeid",
                      "change_indicator",
                      "school_name",
                      "loc_name",
                      "address1",
                      "address2",
                      "city",
                      "state",
                      "county_code",
                      "country",
                      "zip",
                      "fp_name",
                      "eligible"
                    )
                  ))
  
  #filter for title 4 eligible only (~17000)
  peps<-peps%>%
    filter(eligible=="Y")
  
  #filter out international (~16500) 
  peps<-peps%>%
    filter(!is.na(state)) #international 
  
  #filter out institutions that do not start with 0 (currently confirming what is going on with these) (~14000)
  peps<-peps%>%filter(substr(opeid, 1, 1) == "0")
  
  peps<-peps%>%
    mutate(opeid6=substr(opeid,1,6)) #root id
  
  #add peps indicator
  peps<-peps%>%
    mutate(peps=1) 
  
  #add main indicator
  peps<-peps%>%
    mutate(main=ifelse(substr(opeid, nchar(opeid)-1, nchar(opeid)) == "00", 1, 0))
  
  #add year
  peps<-peps%>%
    mutate(year=i)
  
  name<-paste("peps",i, sep="_") 
  assign(name, peps)
  
  peps<-peps%>%
    select(-year, -main)
  
  
  
  #Read in IPEDS Data
  ################################################################################
  ipeds<-read_csv(here("data", "raw", "ipeds", paste0("ipeds_",i,".csv")))
  
  #filter for title 4 eligible only (~6000)
  ipeds<-ipeds%>%
    filter(pset4flg==1)
  
  #Replace missing digits in OPEID
  ipeds<-ipeds%>%
    mutate(opeid1=as.character(ipeds$opeid))
  
  ipeds$opeid1 <- str_pad(ipeds$opeid1, width = 8, side = "left", pad = "0")
  
  ipeds<-ipeds%>%
    select(-opeid)%>%
    rename(opeid=opeid1)
  
  #add main campus indicator 
  ipeds<-ipeds%>%
    mutate(main=ifelse(substr(opeid, nchar(opeid)-1, nchar(opeid)) == "00", 1, 0))
  
  #filter out if opeid doesn't start with 0 (~20 filtered out)
  ipeds<-ipeds%>%filter(substr(opeid, 1, 1) == "0")
  
  ##rename address variable so there are not duplicates with peps
  ipeds<-ipeds%>%
    rename(addr_ipeds=addr)%>%
    rename(city_ipeds=city)%>%
    rename(zip_ipeds=zip)
  
  #filter out other duplicates, removing second for now because it seems to be that non-main campuses are sorted second 
  ipeds <- ipeds %>%
    group_by(opeid) %>%
    mutate(has_duplicate_opeid = n() > 1) %>%
    ungroup()
  
  ipeds <- ipeds %>% arrange(opeid)
  
  ipeds <- ipeds %>%
    group_by(opeid) %>%
    filter(row_number() == 1) %>%
    ungroup()
  
  ipeds<-ipeds%>%
    mutate(opeid6=substr(opeid,1,6)) #root id
  
  #add ipeds indicator
  ipeds<-ipeds%>%
    mutate(ipeds=1) 
  
  #rename county code
  ipeds<-ipeds%>%
    rename(county_code_ipeds=countycd)
  
  
  name<-paste("ipeds",i, sep="_") 
  assign(name, ipeds)
}



#Merge IPEDs and PEPs Data
################################################################################

###Step One: Exactly match on OPEID, these are insts in both datasets (~5483)
exact_match<-peps%>%
  inner_join(ipeds, by=c("opeid", "opeid6"))%>%
  mutate(exact_match=1)

###Step Two: Match branches in peps only to main campus from IPEDS using root OPEID (digits 1-6) (~9000)

#filter out unmatched insts from peps
unmatched_peps<-anti_join(peps,exact_match, by=c("opeid"))

#create a df that is just main campuses from ipeds
ipeds_main<-ipeds%>%
  filter(main==1)

#match main(IPEDS) to branch(PEPS)
ipeds_main<-ipeds_main%>%
  rename(opeid_ipeds=opeid)

unmatched_peps<-unmatched_peps%>%
  rename(opeid_peps=opeid)

match_opeid6<- merge(ipeds_main, unmatched_peps, by = "opeid6", all.x = FALSE)

match_opeid6<-match_opeid6%>%mutate(match_opeid6=1)

#save a df of unmatched peps for reference (~300) 
  #Note: these are mostly religious insts and small technical schools like hair salons, not keeping for now 
unmatched_peps<- anti_join(unmatched_peps, match_opeid6, by = "opeid6")

unmatched_peps<-unmatched_peps%>%
  mutate(unmatched_peps=1)%>%
  mutate(year=as.numeric(i))

#Create a df of all matched peps insts from exact match and branch-main match 
  #Note: joined_df+unmatched_peps should equal total number in peps
joined_df_temp<-bind_rows(exact_match, match_opeid6)

#recover anything unmatched from ipeds (~400 without admin units)
  #NOTE: need to figure out why these are not in PEPs 
unmatched_ipeds<-anti_join(ipeds,joined_df_temp, by=c("opeid"))

unmatched_ipeds<-unmatched_ipeds%>%
  mutate(unmatched_ipeds=1)

#Create a df of all match peps insts and unmatched ipeds and unmatched peps 
joined_df<-bind_rows(joined_df_temp,unmatched_ipeds)

#save separate dfs
name<-paste("unmatched_ipeds",i, sep="_") #
assign(name, unmatched_ipeds)

name<-paste("unmatched_peps",i, sep="_") #this ranges from 300-1000, need to deal with this 
assign(name, unmatched_peps)

#save yearly df
name<-paste("joined_df",i, sep="_")
assign(name, joined_df)
}

###############################################################################
#Append Data 
###############################################################################
joined_df<-bind_rows(joined_df_2010, joined_df_2015, joined_df_2020)

unmatched_peps<-bind_rows(unmatched_peps_2010,unmatched_peps_2015, unmatched_peps_2020)

peps_full<-bind_rows(peps_2010,peps_2015,peps_2020 )

ipeds_full<-bind_rows(ipeds_2010, ipeds_2015, ipeds_2020)

###############################################################################
#Clean Data
###############################################################################

###limit sample 
###############################################################################
#filter out administrative units
joined_df<-joined_df%>%filter(sector!=0)

#filter out graduate only
joined_df<-joined_df%>%filter(instcat!=1)%>%filter(instcat!=5)
joined_df<-joined_df%>%filter(ugoffer!=2)

#filter out states outside 50 US
joined_df <- joined_df%>%
  filter(!(stabbr %in% c("PR", "PW", "AS", "FM", "GU", "MH", "MP", "VI")))

#filter out if programs are exclusively distance
joined_df <- joined_df%>%
  filter(distnced!=1)

  
###remove unnecessary variables
###############################################################################
joined_df <-joined_df %>%
   select(-sector, -pset4flg, -instcat, -record_type,
          -school_name, -fp_name, -eligible, -country, -distnced, 
          -Bachelors, -Masters, -PhD, -"Cert> 1", -Postbac, -Associates, -"Cert<1", 
          -bachelor_cohort_4,-bachelor_completers_4,-degree_cohort_4, -degree_completers_4, 
          -degree_cohort_2,-degree_completers_2, -name, -cendiv, -cendivnm,
          -has_duplicate_opeid, -ugoffer, -school_name, 
          -country, -fp_name, -eligible)

joined_df <-joined_df %>%
  select(-change_indicator, -obereg, -locale,
         -cenregnm, -csa, -region)

joined_df <-joined_df %>% #removing carnegie classification for now
  select(-c18ipug, -c15basic, -carnegie)



###fill in address information for institutions only in IPEDS
###############################################################################
joined_df <-joined_df %>%
  mutate(address1=ifelse(is.na(address1) & unmatched_ipeds==1, addr_ipeds,address1))%>%
  mutate(city=ifelse(is.na(city) & unmatched_ipeds==1, city_ipeds,city))%>%
  mutate(state=ifelse(is.na(state) & unmatched_ipeds==1, stabbr,state))%>%
  mutate(zip=ifelse(is.na(zip) & unmatched_ipeds==1, zip_ipeds,zip))%>%
  mutate(county_code=ifelse(is.na(county_code) & unmatched_ipeds==1, county_code_ipeds, county_code))

#clean county_code so codes coming from ipeds and peps is consistent
joined_df <-joined_df %>%
  mutate(county_code=ifelse(nchar(county_code) == 4, substr(county_code, 2, 4), county_code))

#filtered out old ipeds address variables
joined_df<-joined_df%>%select(-city_ipeds,-addr_ipeds,-zip_ipeds,-stabbr, -county_code_ipeds)

##fill in opeid_ids
###############################################################################
joined_df<-joined_df%>%
  mutate(opeid=ifelse(is.na(opeid), opeid_peps, opeid))

###rename and label variables
###############################################################################
joined_df <-joined_df%>%
  rename(branch_name=loc_name)%>%
  rename(main_name=instnm)

joined_df<-joined_df%>%
  mutate(control=ifelse(control==1, "public",
                 ifelse(control==2, "private",
                ifelse(control==3, "for-proft","na"))))

joined_df<-joined_df%>%
  mutate(grad_rate=grad_rate_4)%>%
  mutate(grad_rate=ifelse(grad_rate==0, grad_rate_2,grad_rate_4)) #a lot of missing data from ipeds

joined_df<-joined_df%>%
  select(-grad_rate_2, -grad_rate_4)

joined_df<-joined_df%>%
  mutate(iclevel=ifelse(iclevel==1,"four year",
                 ifelse(iclevel==2, "two year",
                 ifelse(iclevel==3, "less than two year", "na"))))

joined_df<-joined_df%>%
  mutate(deggrant=ifelse(deggrant==1,"degree-granting",
                  ifelse(iclevel==3, "non-degree-granting", "na")))

joined_df<-joined_df%>%
  mutate(hbcu=ifelse(hbcu==2,0,hbcu)) #recode 0/1

joined_df<-joined_df%>%
  mutate(tribal=ifelse(tribal==2,0,tribal))

joined_df<-joined_df%>%
  mutate(instsize=ifelse(instsize==1,"under 1,000",
                        ifelse(instsize==2, "1,000-4,999",
                        ifelse(instsize==3, "5,000-9,999",
                        ifelse(instsize==4, "10,000-19,999",
                        ifelse(instsize==5, "20,000 and above", "na"))))))

joined_df<-joined_df%>%
  select(-longitud, -latitude)

#fill in branch names if from ipeds only 
joined_df<-joined_df%>%
  mutate(branch_name=ifelse(is.na(branch_name), main_name, branch_name))

#merge in unmatched peps
  #NOTE: 1% of data is missing ipeds, 4% is missing peps 
joined_df<-bind_rows(joined_df, unmatched_peps)

joined_df<-joined_df%>%
  mutate(opeid=ifelse(is.na(opeid), opeid_peps, opeid))

#redefine main campus indicator
  #note: this is so unmatched institutions from peps have correct branch/main indicator
joined_df<-joined_df%>%
  select(-main)%>%
  mutate(main=ifelse(substr(opeid, nchar(opeid)-1, nchar(opeid)) == "00", 1, 0))


###############################################################################
#Merge in urbanicity indicators
###############################################################################
zips<-read_excel(here("data", "raw", "full-ZCTA-urban-suburban-rural-classification.xlsx"))

#add leading 0s
zips<-zips%>%
  mutate(ZCTA=str_pad(as.character(ZCTA), width = 5, side = "left", pad = "0"))

#recode urbancity measure
zips<-zips%>%
  mutate(locale=ifelse(classification==1,"urban",
                  ifelse(classification==2, "suburban",
                  ifelse(classification==3, "rural", "na"))))
zips<-zips%>%
  select(-classification,-density)

zips<-zips%>%
  rename(zip=ZCTA)

#clean zipcode
joined_df$zip <- substr(joined_df$zip, 1, 5)

#merge
joined_df<-joined_df%>%
  left_join(zips, by="zip")

###############################################################################
#Create region indicator
###############################################################################
joined_df$division <- ifelse(joined_df$state %in% c("CT", "ME", "MA", "NH", "RI", "VT"), "New England",
                             ifelse(joined_df$state %in% c("NJ", "NY", "PA"), "Middle Atlantic",
                              ifelse(joined_df$state %in% c("IL", "IN", "MI", "OH", "WI"), "East North Central",
                              ifelse(joined_df$state %in% c("IA", "KS", "MN", "MO", "NE", "ND", "SD"), "West North Central",
                               ifelse(joined_df$state %in% c("DE", "FL", "GA", "MD", "NC", "SC", "VA", "WV", "DC"), "South Atlantic",
                               ifelse(joined_df$state %in% c("AL", "KY", "MS", "TN"), "East South Central",
                              ifelse(joined_df$state %in% c("AR", "LA", "OK", "TX"), "West South Central",
                              ifelse(joined_df$state %in% c("AZ", "CO", "ID", "MT", "NV", "NM", "UT", "WY"), "Mountain",
                              ifelse(joined_df$state %in% c("AK", "CA", "HI", "OR", "WA"), "Pacific", NA)))))))))

###############################################################################
###Output file
###############################################################################
write_csv(joined_df, here("data","cleaned","joined.csv"))
write_csv(peps_full, here("data","cleaned","peps_full.csv"))
write_csv(ipeds_full, here("data","cleaned","ipeds_full.csv"))









  











