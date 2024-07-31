#########################
# Create df for Branch Project
# CF
# 3/8
#########################

setwd("/Users/coralflanagan1/Desktop/projects/msa/scripts")

library(tidyverse)
library(here)
library(readxl)
library(tigris)
library(tidycensus)
library(sf)
library(httr)

#note: Modelling is designed to aggregate up from this tract level, so downloading data from that  

############################################
#Download 5-year Estimates ACS at Tract-Level 
###########################################
#Employment, Population, Enrollment, Geoms 

#create df of state names for loop 
states<-state.name

#Census API 
census_api_key("b27a265fe0dc7c49bd9281d6bc778637f10685e3")
options(tigris_use_cache = TRUE)

###Public Enrollment 
enrollment<-NULL

for(i in states) {
for (y in c(2012,2017,2022)){

tab_name="B14004"

enrollment_temp<-get_acs(geography = "tract",
                         table = tab_name,
                         summary_var = paste0(tab_name,"_001"),
                         geometry = TRUE,
                         state=i,
                         cache_table = TRUE,
                         year=y)

enrollment_temp<-
  enrollment_temp%>%
  rename_all(tolower)%>%
  filter(variable%in%c(
    "B14004_005", # Males enrolled in public college
    "B14004_021" #Females enrolled in public college
  ))%>%
  group_by(geoid,name)%>%
  summarize(enrollment=sum(estimate))%>%
  filter(str_detect(name, "Micro Area",negate=TRUE))%>%
  separate(name,sep=",",into =c("area","state"))%>%
  mutate(state=str_trim(str_remove(state, "Metro Area")))

enrollment_temp<-enrollment_temp%>%
  mutate(year=paste(y))

enrollment<-rbind(enrollment, enrollment_temp)
} 
}

write_rds(enrollment, here("data","cleaned","enrollment_cbsa_3per.rds"))

###Private Enrollment 
enrollment_private<-NULL

for(i in states) {
for (y in c(2012,2017,2022)){
  
  tab_name="B14004"
  
  enrollment_private_temp<-get_acs(geography = "tract",
                                   table = tab_name,
                                   summary_var = paste0(tab_name,"_001"),
                                   state=i,
                                   geometry = FALSE,
                                   cache_table = TRUE,
                                   year=y)
  
  enrollment_private_temp<-
    enrollment_private_temp%>%
    rename_all(tolower)%>%
    filter(variable%in%c(
      "B14004_010", #Males enrolled in private college
      "B14004_026" #Females enrolled in private college
    ))%>%
    group_by(geoid,name)%>%
    summarize(enrollment_private=sum(estimate))%>%
    filter(str_detect(name, "Micro Area",negate=TRUE))%>%
    separate(name,sep=",",into =c("area","state"))%>%
    mutate(state=str_trim(str_remove(state, "Metro Area")))
  
  enrollment_private_temp<-enrollment_private_temp%>%
    mutate(year=paste(y))
  
  enrollment_private<-rbind(enrollment_private, enrollment_private_temp)
  
}
}

write_rds(enrollment, here("data","cleaned","enrollment_private_cbsa_3per.rds"))


###Employment

employment<-NULL

for(i in states) {
for (y in c(2012,2017,2022)){
  
  tab_name<-"B23025"

  employment_temp<-get_acs(geography="tract",  
                           table=tab_name,
                           state=i,
                           summary_var=paste0(tab_name,"_001"),
                           cache_table = TRUE, 
                           year=y)
  employment_temp<-
    employment_temp%>%
    rename_all(tolower)%>%
    filter(variable=="B23025_004")%>%  
    group_by(geoid,name)%>%
    summarize(employment=sum(estimate),
              total_population=first(summary_est))%>%
    filter(str_detect(name, "Micro Area",negate=TRUE))%>%
    separate(name,sep=",",into =c("area","state"))%>%
    mutate(state=str_trim(str_remove(state, "Metro Area")))
  
  employment_temp<-employment_temp%>%
    mutate(year=paste(y))
  
  employment<-rbind(employment, employment_temp)
  
} 
}

write_rds(employment, here("data","cleaned","employment_cbsa_3per.rds"))

###Employment in Manufacturing

manufacture<-NULL

for(i in states) {
  for (y in c(2012,2017,2022)){
    
    tab_name<-"C24030"
    
    manufacture_temp<-get_acs(geography="tract",  
                             table=tab_name,
                             state=i,
                             summary_var=paste0(tab_name,"_001"),
                             cache_table = TRUE, 
                             year=y)
    list_of_vars<-c("C24030_003",
                    "C24030_006",
                    "C24030_007",
                    "C24030_030",
                    "C24030_033",
                    "C24030_034"
    )
    

    manufacture_temp<-
      manufacture_temp%>%
      rename_all(tolower)%>%
      mutate(industry_group=ifelse(
        variable%in%list_of_vars ,"extract_construct_manufacture","other"))%>%
      group_by(geoid,name,industry_group)%>%
      summarize(employment=sum(estimate),
                total_population=first(summary_est))%>%
      pivot_wider(names_from = "industry_group",values_from = "employment")%>%
      select(-other,-total_population)
    
    manufacture_temp<-manufacture_temp%>%
      mutate(year=paste(y))
    
    manufacture<-rbind(manufacture, manufacture_temp)
    
  } 
}

write_rds(manufacture, here("data","cleaned","manufacture_cbsa_3per.rds"))

##Population and Geometries

#create blank dfs 
geoms_tr<-NULL

#Geo data for census tracts (downloaded with population data) 
for(i in states) {
  for (y in c(2012,2017,2022)){
    
    geoms<-get_acs(geography="tract", 
                   state=i,
                   variable="C24030_001", #population for each tract 
                   cache_table = TRUE, 
                   geometry= TRUE, 
                   year=y)
    
    geoms<-geoms%>%
      mutate(year=y)
    
    geoms<-geoms%>%
      rename_all(tolower)
    
    geoms_tr<-rbind(geoms_tr,geoms)
    
    
  }
}

geoms_tr<- geoms_tr%>%
  rename(total_population=estimate)

write_rds(geoms_tr,here("data","cleaned","geoms_tr.rds"))

### MSA Identifier 
msa<-NULL

for (y in c(2012,2017,2022)){
  
  msa_year<-read_xls(here("data","cleaned",paste0("msa_",y,".xls")))
  
  msa_year<-msa_year%>%
    mutate(year=as.character(y))%>%
    rename(st_fips="FIPS State Code",
           ct_code="FIPS County Code", 
           msa_code="CBSA Code", 
           msa_name="CBSA Title",
           msa_type="Metropolitan/Micropolitan Statistical Area")%>%
    select(st_fips, ct_code, msa_code, msa_name, msa_type, year)
  
  
  msa<-rbind(msa,msa_year)
  
}

############################################
#Merge Datasets 
############################################
# reload datasets if needed
enrollment<-read_rds(here("data","cleaned","enrollment_cbsa_3per.rds"))
enrollment_private<-read_rds(here("data","cleaned","enrollment_private_cbsa_3per.rds"))
manufacture<-read_rds(here("data","cleaned","manufacture_cbsa_3per.rds"))
employment<-read_rds(here("data","cleaned","employment_cbsa_3per.rds"))
geoms_tr<-read_rds(here("data","cleaned","geoms_tr.rds"))

#clean up datasets
enrollment<-enrollment%>%
  rename(county=state)

enrollment<-enrollment%>%
  rename(enrollment_private=enrollment)
  
enrollment<-enrollment%>%
  st_drop_geometry()

employment<-employment%>%
  rename(county=state)

geoms<-geoms_tr%>%
  select(-name, -variable, -moe,-total_population)

geoms<-geoms%>%
  mutate(year=as.character(year))

###join datasets 
full<-enrollment%>%left_join(enrollment_private,by=c("geoid","area", "county", "year"))%>%
  left_join(employment,by=c("geoid","area", "county", "year"))%>%
  left_join(manufacture,by=c("geoid", "year"))

full<-full%>%
  left_join(geoms,by=c("geoid","year"))

full<-full%>%
  mutate(st_fips=substr(geoid, 1,2))%>%
  mutate(tract_code=substr(geoid,6,11))%>%
  mutate(ct_code=substr(geoid,3,5))

full<-full%>%
  rename(enrollment_pub=enrollment)


full<-full%>%
  mutate(enrollment=enrollment_pub+enrollment_private)

full<-full%>%
  left_join(msa,by=c("st_fips","ct_code", "year"))

full_g<- full%>% 
  st_as_sf(crs = "NAD83")

full_c<-full%>%
  st_as_sf(crs = "NAD83")%>%
  st_centroid()



############################################
#Save 
###########################################

write_rds(full_g,file=here("data","cleaned",paste0("acs_g_tr_3per.Rds")))
write_rds(full_c,file=here("data","cleaned",paste0("acs_c_tr_3per.Rds")))

#save a version in msa folder too 
setwd("/Users/coralflanagan1/Desktop/projects/msa/data/cleaned")
write_rds(full_c,file=paste0("acs_c_tr_3per.Rds"))



###############################################################################
#MSA-Level Geometries
###############################################################################


#create blank dfs 
geoms_msa<-NULL

#Geo data for census tracts (downloaded with population data) 
  for (y in c(2012,2017,2022)){
    
    geoms<-get_acs(geography="cbsa", 
                   variable="C24030_001", #population for each tract 
                   cache_table = TRUE, 
                   geometry= TRUE, 
                   year=y)
    
    geoms<-geoms%>%
      mutate(year=y)
    
    geoms<-geoms%>%
      rename_all(tolower)
    
    geoms_msa<-rbind(geoms_msa,geoms)
    
    
  }

geoms_msa<- geoms_msa%>%
  rename(total_population=estimate)

geoms_msa<-geoms_msa%>%
  select(-variable, -moe)

geoms_msa<-geoms_msa%>%
 mutate(year=ifelse(year==2012, 2010,year))%>%
  mutate(year=ifelse(year==2017, 2015,year))%>%
  mutate(year=ifelse(year==2022, 2020,year))

#limit to metro areas: 
include_text <- grepl("Metro Area", geoms_msa$name)
geoms_msa <- geoms_msa[include_text, ]



write_rds(geoms_msa,here("data","cleaned","geoms_msa.rds"))



