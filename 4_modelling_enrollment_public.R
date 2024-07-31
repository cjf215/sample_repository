########################
# Building and Cross Validating Key Models
# Will Doyle and Coral Flanagan
# Generate measure of distance; cross validate
# 2023-09-12
################################
setwd("/Users/coralflanagan1/Desktop/projects/msa/scripts")

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
library(ggthemes)
library(sp)
library(distRcpp)
library(dplyr)
library(tidyr)
library(stargazer)




#############################################
# Load data
#############################################

## ACS spatial data with census tracts 
#############################################
full_c<-readRDS(file=here("data","cleaned",paste0("acs_c_tr_3per19.Rds")))

#filter out Hawaii and Alaska
full_c<-full_c%>%
  filter(st_fips!="02" & st_fips!="15")

#Filter out Micro Areas
full_c<-full_c%>%
  filter(msa_type=="Metropolitan Statistical Area")

#Filter out Empty Polygons
full_c<-full_c[! st_is_empty(full_c), ]


full_c<-full_c%>%
  mutate(enrollment_log=log(enrollment))%>%
  mutate(total_population_log=log(total_population))%>%
  mutate(extract_construct_manufacture_log=log(extract_construct_manufacture))

# Replace -Inf with 0
full_c$total_population_log <- ifelse(full_c$total_population_log == -Inf, 0, full_c$total_population_log)
full_c$enrollment_log <- ifelse(full_c$enrollment_log == -Inf, 0, full_c$enrollment_log)
full_c$extract_construct_manufacture_log <- ifelse(full_c$extract_construct_manufacture_log == -Inf, 0, full_c$extract_construct_manufacture_log)

full_c<-full_c%>%
  mutate(st_fips = str_replace(st_fips, "^0+", ""))

acs_c<-full_c%>%
  st_as_sf(crs="NAD83")%>%
  as_Spatial()

acs_coords=coordinates(acs_c)

colnames(acs_coords)<-c("lon","lat")

full_c<-full_c%>%
  bind_cols(acs_coords)

## Ipeds
#############################################

ipeds<-readRDS(file=here("data","cleaned",paste0("institutions.Rds")))

ipeds<-ipeds%>%
  mutate(state=stabbr)

ipeds<-ipeds%>%
  filter(sector!=99)%>%
  filter(sector!=0)%>%
  filter(sector!=9)%>%
  rename(tuit=tuition1)%>%
  mutate(tuit=as.numeric(tuit))

#limit to public only 
ipeds<-ipeds%>%
  filter(control==1)

ipeds<-ipeds%>%
  mutate(net_price=ifelse(!is.na(net_price_pub), 
                          net_price_pub, net_price_private))

#limit to keep sample consistent
ipeds <- ipeds[complete.cases(ipeds[, c("tuit", "fteug",  "net_price")]), ]

## Second Version
ipeds_c<-ipeds

## Renamed vars in second version
ipeds_c<-ipeds_c%>%rename(lon=longitud,lat=latitude)

ipeds_c<-ipeds_c%>%
  rename(st_fips=stfips)

#as spatial 
ipeds<-ipeds%>%
  st_as_sf(coords = c("longitud", "latitude"), crs = "NAD83") %>%
  as_Spatial()



###############################################################################
#Cross Validate Different Penalties 
###############################################################################

for (i in c("fteug","tuit","net_price")) {
  
  reps<-1000
  rmse_df<-NULL
  
  ##cross validation
  for (p in seq(1,4,by=.5)){ 
    mean_df<-dist_weighted_mean(x_df=full_c,
                                y_df=ipeds_c,
                                measure_col=i,
                                decay=p,
                                x_id="geoid")
    
    
    ## add to areal data
    
    acs_sub<-acs_c@data
    
    acs_sub$idw<-mean_df$wmeasure
    
    acs_sub<-acs_sub%>%
      filter(st_fips!=72)
    
    ## aggregate idws to census tract level
    
    acs_sub<-acs_sub%>%
      group_by(msa_name)%>%
      summarize(idw=weighted.mean(idw,w=total_population),
                enrollment=sum(enrollment),
                total_population=sum(total_population),
                extract_construct_manufacture=sum(extract_construct_manufacture)
      )
    
    
    ## Wrangle
    acs_sub<-acs_sub%>%mutate(log_enrollment=log(enrollment))
    
    ## cross validate
    
    lm_mod<-linear_reg()%>%
      set_engine("lm")%>%
      set_mode("regression")
    
    lm_formula<-as.formula("log_enrollment~total_population+extract_construct_manufacture+idw")
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors()) 
    
    
    ## fit to data prepped for cross validate
    
    acs_sub_rs<-mc_cv(acs_sub,times=reps) #pull monte carlo samples
    
    lm_workflow<-workflow()%>%
      add_model(lm_mod)%>%
      add_recipe(lm_recipe)
    
    doParallel::registerDoParallel()
    
    lm_cv<-lm_workflow%>%
      fit_resamples(acs_sub_rs)
    
    ## Extract RMSE
    
    rmse<-lm_cv%>%
      unnest(.metrics)%>%
      filter(.metric=="rmse")%>%
      select(.estimate)%>%
      rename_with(~paste0("RMSE=",round(p,4)))
    
    rmse_df<-bind_cols(rmse,rmse_df)
  }
  
  rmse_df<-rmse_df%>%
    pivot_longer(names_to="Penalty",cols=everything())%>%
    mutate(x_var=paste(i))
  
  save(rmse_df,file=here("data","cleaned", paste0("cv_results_all_insts_",i,".Rdata")))
  
  ## aggregating results by penalty number
  rmse_df%>%
    group_by(Penalty)%>%
    summarize(mean_value=mean(value))%>%
    arrange(mean_value)
  
  ## Holding named data frame in environment
  name<-paste("rmse_df",i, sep="_")
  
  ## assigning name
  assign(name, rmse_df)
  
}

# Graph RMSE 
####################################################################

#load(here("data","cleaned", "cv_results_all_insts_full.Rdata") )

rmse_df_full<-rmse_df_fteug%>%rbind(rmse_df_net_price, rmse_df_tuit)

rmse_df_full<-rmse_df_full%>%
  mutate(weight=str_sub(Penalty,6))

#filter and add value labels
rmse_df_full<-rmse_df_full%>%
  mutate(x_var=ifelse(x_var=="fteug", "UG Enrollment",
                      ifelse(x_var=="tuit", "Tuition",
                             ifelse(x_var=="net_price","Net Price","NA"))))

rmse_df_full%>%
  ggplot(aes(x=value,fill=weight))+
  geom_density(alpha=.2)+
  facet_wrap(~x_var)


rmse_df_full%>%
  group_by(x_var, weight)%>%
  summarize(min=min(value),max=max(value),median=median(value))%>%
  ggplot(aes(y=median, x=as_factor(weight),color=weight))+
  geom_point()+
  theme_few()+
  labs(x="Weight", y="Median")+
  facet_wrap(~x_var)+
  theme(
    text = element_text(family = "serif") 
  ) 

ggsave(here("figures","cross_val","rmse_logged_enrollment_pub.jpg"))



###############################################################################
# Run Regression Results 
###############################################################################

#get rid of 0 so no nas
full_c<-full_c%>%
  mutate(extract_construct_manufacture = ifelse(extract_construct_manufacture == 0, extract_construct_manufacture + 1, extract_construct_manufacture))%>%
  mutate(total_population = ifelse(total_population == 0, total_population + 1, total_population))%>%
  mutate(total_population = ifelse(total_population == 0, total_population + 1, total_population))


#All
###############################

table1<-NULL

for (i in c("fteug","tuit", "net_price")) {
  
  
  for (p in seq(1,4,by=.5)){
    mean_df<-dist_weighted_mean(x_df=full_c,
                                y_df=ipeds_c,
                                measure_col=i,
                                decay=p,
                                x_id="geoid")
    
    
    ## add to areal data
    
    acs_sub<-acs_c@data
    
    acs_sub$idw<-mean_df$wmeasure
    
    acs_sub<-acs_sub%>%
      filter(st_fips!=72)
    
    ## aggregate idws to census tract level
    
    acs_sub<-acs_sub%>%
      group_by(msa_name)%>%
      summarize(idw=weighted.mean(idw,w=total_population),
                enrollment=sum(enrollment),
                total_population=sum(total_population),
                extract_construct_manufacture=sum(extract_construct_manufacture)
      )
    
    
    ## Wrangle
    acs_sub<-acs_sub%>%mutate(log_enrollment=log(enrollment))
    
    
    lm_mod<-linear_reg()%>%
      set_engine("lm")%>%
      set_mode("regression")
    
    lm_formula<-as.formula("log_enrollment~total_population+extract_construct_manufacture+idw")
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors())
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors()) 
    
    lm_workflow<-workflow()%>%
      add_model(lm_mod)%>%
      add_recipe(lm_recipe)
    
    lm_fitted<-lm_workflow%>%fit(acs_sub)
    
    tab_results<-lm_fitted%>%tidy()%>%
      mutate(x_var=i)%>%
      mutate(p=p)
    
    table1<-rbind(table1,tab_results)
    
  }
}

#clean df
table1<-table1%>%
  filter(term=="idw")%>%
  select(estimate,std.error,x_var,p)%>%
  mutate(std.error=round(std.error,digits=3))%>%
  mutate(std.error=paste0("(",std.error, ")"))%>%
  mutate(estimate=round(estimate, digits=3))%>%
  mutate(estimate=as.character(estimate))

#pivot longer
table1<-table1%>%
  pivot_longer(cols=c("estimate", "std.error"),
               names_to="term",
               values_to="value")

#pivot wider
table1<-table1%>%
  pivot_wider(id_cols=c(x_var, term),
              names_from= p,
              values_from=value)

# Create table
result_table <- as.data.frame(table1)

# Print the table
stargazer(result_table,
          digits = 1,
          digits.extra = 1,
          summary = FALSE,
          type = "text",
          title = "Table 1: Results All",
          out = here("figures", "tables", "table1_all_pub.html"))



#Instate All
###############################
table2<-NULL

#create a list of st_fips
st_fips <- unique(full_c$st_fips)

for (i in c("tuit","net_price","fteug")) {
  
  for (p in seq(1,4,by=.5)){
    mean_df<-NULL
    
    #loop through st_fips
    for(s in st_fips) {
      
      #filter to instate only 
      full_c_st<-full_c%>%
        filter(st_fips==s)
      ipeds_c_st<-ipeds_c%>%
        filter(st_fips==s)
      
      #calculate w_measure 
      temp<-dist_weighted_mean(x_df=full_c_st,
                               y_df=ipeds_c_st,
                               measure_col=i,
                               decay=p,
                               x_id="geoid")
      
      #add to df 
      mean_df<-rbind(mean_df,temp)
    }
    
    
    
    ## add to areal data
    
    acs_sub<-acs_c@data
    
    acs_sub$idw<-mean_df$wmeasure
    
    acs_sub<-acs_sub%>%
      filter(st_fips!=72)
    
    
    acs_sub<-acs_sub%>%
      filter(idw!=0) #filter out if no insts of that level in MSA
    
    ## aggregate idws to census tract level
    
    acs_sub<-acs_sub%>%
      group_by(msa_name)%>%
      summarize(idw=weighted.mean(idw,w=total_population),
                enrollment=sum(enrollment),
                total_population=sum(total_population),
                extract_construct_manufacture=sum(extract_construct_manufacture)
      )
    
    
    ## Wrangle
    acs_sub<-acs_sub%>%mutate(enrollment=log(enrollment))
    
    
    lm_mod<-linear_reg()%>%
      set_engine("lm")%>%
      set_mode("regression")
    
    lm_formula<-as.formula("enrollment~total_population+extract_construct_manufacture+idw")
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors())
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors()) 
    
    lm_workflow<-workflow()%>%
      add_model(lm_mod)%>%
      add_recipe(lm_recipe)
    
    
    lm_fitted<-lm_workflow%>%fit(acs_sub) #issue 
    
    tab_results<-lm_fitted%>%tidy()%>%
      mutate(x_var=i)%>%
      mutate(p=p)
    
    table2<-rbind(table2,tab_results)
  }
}

#clean df
table2<-table2%>%
  filter(term=="idw")%>%
  select(estimate,std.error,x_var,p)%>%
  mutate(std.error=round(std.error,digits=3))%>%
  mutate(std.error=paste0("(",std.error, ")"))%>%
  mutate(estimate=round(estimate, digits=3))%>%
  mutate(estimate=as.character(estimate))

#pivot longer
table2<-table2%>%
  pivot_longer(cols=c("estimate", "std.error"),
               names_to="term",
               values_to="value")

#pivot wider
table2<-table2%>%
  pivot_wider(id_cols=c(x_var, term),
              names_from= p,
              values_from=value)

# Create table
result_table <- as.data.frame(table2)

# Print the table
stargazer(result_table,
          digits = 1,
          digits.extra = 1,
          summary = FALSE,
          type = "text",
          title = "Table 2: In State",
          out = here("figures", "tables", "table2_instate_pub.html"))


# Instate 2 Year Only 
###############################

table3<-NULL

#create a list of st_fips
st_fips <- unique(full_c$st_fips)

for (i in c("tuit","net_price","fteug")) {
  
  for (p in seq(1,4,by=.5)){
    mean_df<-NULL
    
    #loop through st_fips
    for(s in st_fips) {
      
      #filter to instate only 
      full_c_st<-full_c%>%
        filter(st_fips==s)
      ipeds_c_st<-ipeds_c%>%
        filter(st_fips==s)%>%
        filter(iclevel==2) #2yr only 
      
      #calculate w_measure 
      temp<-dist_weighted_mean(x_df=full_c_st,
                               y_df=ipeds_c_st,
                               measure_col=i,
                               decay=p,
                               x_id="geoid")
      
      #add to df 
      mean_df<-rbind(mean_df,temp)
    }
    
    
    
    ## add to areal data
    
    acs_sub<-acs_c@data
    
    acs_sub$idw<-mean_df$wmeasure
    
    acs_sub<-acs_sub%>%
      filter(st_fips!=72)
    
    
    acs_sub<-acs_sub%>%
      filter(idw!=0) #filter out if no insts of that level in MSA
    
    ## aggregate idws to census tract level
    
    acs_sub<-acs_sub%>%
      group_by(msa_name)%>%
      summarize(idw=weighted.mean(idw,w=total_population),
                enrollment=sum(enrollment),
                total_population=sum(total_population),
                extract_construct_manufacture=sum(extract_construct_manufacture)
      )
    
    
    ## Wrangle
    acs_sub<-acs_sub%>%mutate(enrollment=log(enrollment))
    
    
    lm_mod<-linear_reg()%>%
      set_engine("lm")%>%
      set_mode("regression")
    
    lm_formula<-as.formula("enrollment~total_population+extract_construct_manufacture+idw")
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors())
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors()) 
    
    lm_workflow<-workflow()%>%
      add_model(lm_mod)%>%
      add_recipe(lm_recipe)
    
    
    lm_fitted<-lm_workflow%>%fit(acs_sub) #issue 
    
    tab_results<-lm_fitted%>%tidy()%>%
      mutate(x_var=i)%>%
      mutate(p=p)
    
    table3<-rbind(table3,tab_results)
  }
}

#clean df
table3<-table3%>%
  filter(term=="idw")%>%
  select(estimate,std.error,x_var,p)%>%
  mutate(std.error=round(std.error,digits=3))%>%
  mutate(std.error=paste0("(",std.error, ")"))%>%
  mutate(estimate=round(estimate, digits=3))%>%
  mutate(estimate=as.character(estimate))

#pivot longer
table3<-table3%>%
  pivot_longer(cols=c("estimate", "std.error"),
               names_to="term",
               values_to="value")

#pivot wider
table3<-table3%>%
  pivot_wider(id_cols=c(x_var, term),
              names_from= p,
              values_from=value)

# Create table
result_table <- as.data.frame(table3)

# Print the table
stargazer(result_table,
          digits = 1,
          digits.extra = 1,
          summary = FALSE,
          type = "text",
          title = "Table 3:In State, 2yr Insts",
          out = here("figures", "tables", "table3_instate_2yr_all_pub.html"))

#Instate 4 Year Only 
###############################
table4<-NULL

#create a list of st_fips
st_fips <- unique(full_c$st_fips)

for (i in c("tuit","net_price","fteug")) {
  
  for (p in seq(1,4,by=.5)){
    mean_df<-NULL
    
    #loop through st_fips
    for(s in st_fips) {
      
      #filter to instate only 
      full_c_st<-full_c%>%
        filter(st_fips==s)
      ipeds_c_st<-ipeds_c%>%
        filter(st_fips==s)%>%
        filter(iclevel==1) #4yr only 
      
      #calculate w_measure 
      temp<-dist_weighted_mean(x_df=full_c_st,
                               y_df=ipeds_c_st,
                               measure_col=i,
                               decay=p,
                               x_id="geoid")
      
      #add to df 
      mean_df<-rbind(mean_df,temp)
    }
    
    
    
    ## add to areal data
    
    acs_sub<-acs_c@data
    
    acs_sub$idw<-mean_df$wmeasure
    
    acs_sub<-acs_sub%>%
      filter(st_fips!=72)
    
    
    acs_sub<-acs_sub%>%
      filter(idw!=0) #filter out if no insts of that level in MSA
    
    ## aggregate idws to census tract level
    
    acs_sub<-acs_sub%>%
      group_by(msa_name)%>%
      summarize(idw=weighted.mean(idw,w=total_population),
                enrollment=sum(enrollment),
                total_population=sum(total_population),
                extract_construct_manufacture=sum(extract_construct_manufacture)
      )
    
    
    ## Wrangle
    acs_sub<-acs_sub%>%mutate(enrollment=log(enrollment))
    
    
    lm_mod<-linear_reg()%>%
      set_engine("lm")%>%
      set_mode("regression")
    
    lm_formula<-as.formula("enrollment~total_population+extract_construct_manufacture+idw")
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors())
    
    
    lm_recipe<-recipe(lm_formula,acs_sub)%>%
      step_log(all_numeric_predictors()) 
    
    lm_workflow<-workflow()%>%
      add_model(lm_mod)%>%
      add_recipe(lm_recipe)
    
    
    lm_fitted<-lm_workflow%>%fit(acs_sub) #issue 
    
    tab_results<-lm_fitted%>%tidy()%>%
      mutate(x_var=i)%>%
      mutate(p=p)
    
    table4<-rbind(table4,tab_results)
  }
}

#clean df
table4<-table4%>%
  filter(term=="idw")%>%
  select(estimate,std.error,x_var,p)%>%
  mutate(std.error=round(std.error,digits=3))%>%
  mutate(std.error=paste0("(",std.error, ")"))%>%
  mutate(estimate=round(estimate, digits=3))%>%
  mutate(estimate=as.character(estimate))

#pivot longer
table4<-table4%>%
  pivot_longer(cols=c("estimate", "std.error"),
               names_to="term",
               values_to="value")

#pivot wider
table4<-table4%>%
  pivot_wider(id_cols=c(x_var, term),
              names_from= p,
              values_from=value)

# Create table
result_table <- as.data.frame(table4)

# Print the table
stargazer(result_table,
          digits = 1,
          digits.extra = 1,
          summary = FALSE,
          type = "text",
          title = "Table 4: In State, 4yr Insts",
          out = here("figures", "tables", "table4_instate_4yr_all_pub.html"))





