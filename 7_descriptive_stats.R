########################
# Create Descriptive Tables for Branch MSA Paper
# Coral Flanagan and Will Doyle
# 2022-06-30
################################
library(tidyverse)
library(tidymodels)
library(sf)
library(here)
library(leaflet)
library(gstat)
library(geosphere)
library(doParallel)
library(scales)
library(stargazer)

#set working directory to scripts 

## =============================================================================
## Load and Clean Data
## =============================================================================

#acs
## =============================================================================

full_c_tr<-readRDS(file=here("data","cleaned",paste0("acs_c_tr_peps.Rds")))

#filter out HI, AK
full_c_tr<-full_c_tr%>%
  st_drop_geometry()%>%
  filter(st_fips!="02" & st_fips!="15")

#filter out micropolitan areas 
full_c_tr<-full_c_tr%>%
  filter(msa_type=="Metropolitan Statistical Area")

full_c_tr<-full_c_tr%>%
  select(enrollment,employment, total_population, st_fips, msa_code)%>%
  mutate(enrollment_log=log(enrollment))%>%
  mutate(total_population_log=log(total_population))%>%
  mutate(employment_log=log(employment))

#replace -Inf
# Replace -Inf with 0
full_c_tr$total_population_log <- ifelse(full_c_tr$total_population_log == -Inf, 0, full_c_tr$total_population_log)
full_c_tr$enrollment_log <- ifelse(full_c_tr$enrollment_log == -Inf, 0, full_c_tr$enrollment_log)
full_c_tr$employment_log <- ifelse(full_c_tr$employment_log == -Inf, 0, full_c_tr$employment_log)


full_c_msa<-full_c_tr%>%
  group_by(msa_code)%>%
  summarize(enrollment=sum(enrollment),
            total_population=sum(total_population),
            employment=sum(employment))

#380 total MSAs

##institution characteristics
## =============================================================================

peps<-read_csv(here("data", "cleaned" , "peps_ipeds.csv"))

peps<-peps%>%
  filter(sector%in%c(1,4))

peps<-peps%>%
  select(net_price_pub, grad_rate_4, grad_rate_2, tuition1, fteug)


## =============================================================================
## Create Summary Tables
## =============================================================================

##acs
stargazer(as.data.frame(full_c_tr),
          type="text",
          title="Table 1: Covariates, Census Tracts",
          digits=0,
          out=here("figures", "descriptives","table1_cov_tr.html"))

stargazer(as.data.frame(full_c_msa),
          type="text",
          title="Table 2: Covariates, MSA Aggregated",
          digits=0,
          out=here("figures", "descriptives","table2_cov_msa.html"))

##institutional characteristics 

stargazer(as.data.frame(peps),
          type="text",
          title="Table 3: Institutional Characteristics",
          digits=2,
          out=here("figures","descriptives", "table3_ic.html"))



