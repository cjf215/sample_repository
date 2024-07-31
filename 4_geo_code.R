################################################################################
##Goal: Geocode Joined Dataframe 
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

#note: this file creates a dataset call branch_fall_data.rds, which is saved in the 
#"branch_campus" box folder 

setwd("/Users/coralflanagan1/Desktop/projects/branch_campus/scripts")


#load data
joined_df<-read_csv(here("data","cleaned","joined.csv"))



###############################################################################
#Clean for Geocoding 
###############################################################################

##create a single column with the address
joined_df<-joined_df%>%
  mutate(address=paste(address1, city, state, sep=", "))

joined_df<-joined_df%>%
  mutate(address_full=paste(address, zip, sep=" "))%>%
  select(-address, -address2, -address1)

joined_df<-joined_df%>%
  mutate(address=str_replace(address_full,"North", "N" ))%>%
  mutate(address=str_replace(address_full,"South", "S" ))%>%
  mutate(address=str_replace(address_full,"East", "E" ))%>%
  mutate(address=str_replace(address_full,"West", "W" ))%>%
  mutate(address=str_replace(address_full,"Nwest", "NW" ))%>%
  mutate(address=str_replace(address_full,"Swest", "SW" ))%>%
  mutate(address=str_replace(address_full,"Neast", "NE" ))%>%
  mutate(address=str_replace(address_full,"Seast", "SE" ))%>%
  mutate(address=str_replace(address_full,"Nline", "Northline"))%>%
  mutate(address=str_replace(address_full,"first", "1st" ))%>%
  mutate(address=str_replace(address_full,"second", "2nd" ))%>%
  mutate(address=str_replace(address_full,"third", "3rd" ))%>%
  mutate(address=str_replace(address_full,"fourth", "4th" ))%>%
  mutate(address=str_replace(address_full,"fifth", "5th" )) %>%
  mutate(address=str_replace(address_full,"sixth", "6th" ))%>%
  mutate(address=str_replace(address_full,"seventh", "7th" ))%>%
  mutate(address=str_replace(address_full,"eighth", "8th" ))%>%
  mutate(address=str_replace(address_full,"ninth", "9th" ))%>%
  mutate(address=str_replace(address_full,"tenth", "10th" ))%>%
  mutate(address=str_replace(address_full,"eleventh", "11th" ))%>%
  mutate(address=str_replace(address_full,"twelfth", "12th" ))%>%
  mutate(address=str_replace(address_full,"thirteenth", "13th" ))%>%
  mutate(address=str_replace(address_full,"fourteenth", "14th" ))%>%
  mutate(address=str_replace(address_full,"fifteenth", "15th" )) %>%
  mutate(address=str_replace(address_full,"sixteenth", "16th" ))%>%
  mutate(address=str_replace(address_full,"seventeenth", "17th" ))%>%
  mutate(address=str_replace(address_full,"eighteenth", "18th" ))%>%
  mutate(address=str_replace(address_full,"nineteenth", "19th" ))%>%
  mutate(zip=str_sub(zip,1,5))%>%
  mutate(address=str_c(address_full,
                       ", " ,
                       city,
                       ", ",
                       state,
                       " ",
                       zip))



#limit year: 
joined_df<-joined_df%>%
  filter(year==2020)

##recode for UTF-8 issues
joined_df<-joined_df%>%
  mutate(address_full=utf8_format(address_full))

#filter out PR
joined_df <- joined_df%>%
  filter(!(state %in% c("PR", "PW", "AS", "FM", "GU", "MH", "MP", "VI")))


###############################################################################
#Geocode 
###############################################################################
#note: each section should take around 30 minutes?

df1<-joined_df[1:5000,]
df2<-joined_df[5001:10000,]
df3<-joined_df[10001:15366,]

df1<-df1%>%
  geocode(address = address_full, method = "arcgis", verbose = TRUE)

write_csv(df1, here("data","cleaned","geo_df1_20.csv"))


df2<-df2%>%
  geocode(address = address_full, method = "arcgis", verbose = TRUE)

write_csv(df2, here("data","cleaned","geo_df2_20.csv"))


df3<-df3%>%
  geocode(address = address_full, method = "arcgis", verbose = TRUE)

write_csv(df3, here("data","cleaned","geo_df3_20.csv"))



# # #reload if needed
df1<-read_csv(here("data","cleaned","geo_df1_18.csv"))
df2<-read_csv(here("data","cleaned","geo_df2_18.csv"))
df3<-read_csv(here("data","cleaned","geo_df3_18.csv"))

## Output geocoded dataset
joined_df<-rbind(df1, df2, df3)
write_csv(joined_df, here("data","cleaned","joined_df_geo_2020.csv"))


###merge all years together
for (i in c(10,15,20)) {

file_name <- paste0("joined_df_geo_20", i, ".csv")

df <- read.csv(here("data","cleaned", file_name))
df <-df%>%mutate(year=paste0("20", i))
  
assign(paste0("df_", i), df)
  
}

df_20<-df_20%>%
  select(-X11)

joined_df<-rbind(df_10,df_15,df_20)

#remove any variables we don't need
joined_df<-joined_df%>%
  select(-opeid6,-exact_match,-match_opeid6, -unmatched_ipeds, -record_type,
         -change_indicator, -school_name, -loc_name, -country, -fp_name, -eligible,
         -unmatched_peps, -address, -locale, -division)%>%
  rename(main_ipeds_unitid=unitid)

#save 
write_rds(joined_df, here("data","cleaned","branch_full_data_limited_yrs.rds"))

