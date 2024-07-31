library(tidyverse)
library(here)
library(readxl)
library(tigris)
library(tidycensus)
library(sf)
library(httr)
library(ggplot2)


#load data
load(here("data","cleaned","full_g_sub_2_ipeds.Rds")) 

#filter out non-continguous states
full_g<-full_g%>%
  filter(st_fips!=15 & st_fips!=2 )

full_g<-full_g%>%
  mutate(log_wmeasure=log(wmeasure))

full_g<-pivot_wider(full_g, 
                    id_cols=c(geoid, msa_code), 
                    names_from=measure,
                    values_from=log_wmeasure)

#merge in total population

population<-readRDS(file=here("data","cleaned",paste0("acs_c_tr_peps.Rds")))
population<-population%>%
  select(geoid, total_population)


full_g<-left_join(full_g,population, by="geoid")
  
  
#aggregate up to msa 
full_g<-full_g%>%
  na.omit() %>%
  group_by(msa_code)%>%
  summarize(fteug=weighted.mean(fteug,w=total_population),
            tuit=weighted.mean(tuit,w=total_population),
            net_price=weighted.mean(net_price,w=total_population))

#add in msa-level geoms
census_api_key("b27a265fe0dc7c49bd9281d6bc778637f10685e3")

geoms<-get_acs(geography="cbsa", 
               variable="C24030_001", #population for each tract 
               cache_table = TRUE, 
               geometry= TRUE)

geoms<-geoms%>%
  rename(msa_code=GEOID)

full_g<-left_join(full_g, geoms, by="msa_code")

full_g<-full_g%>%
  select(msa_code, NAME, fteug, tuit, net_price, geometry)

#make it spatial
full_g1<-st_as_sf(full_g)


#rename
full_g1<-full_g1%>%
  rename(Enrollment=fteug)%>%
  rename(Tuition=tuit)%>%
  rename(Net_Price=net_price)

#load US shapefile
us_map <- st_read("cb_2018_us_state_500k.shp")
us_map<-us_map%>%
  filter(NAME!="Hawaii" & NAME!="Alaska" &
         NAME!="Puerto Rico" & NAME!="American Samoa" &
         NAME!="United States Virgin Islands" &
         NAME!="Guam" &
         NAME!="Commonwealth of the Northern Mariana Islands")

plot1<-ggplot() +
  geom_sf(data = us_map, fill = "white", color = "black") +  # Underlay US map
  geom_sf(data = full_g1, aes(fill = Enrollment)) +
  scale_fill_viridis_c( option = "F", trans = "reverse") +
  labs(title = "Panel 1: Logged Enrollment")


plot2<-ggplot() +
  geom_sf(data = us_map, fill = "white", color = "black") +  # Underlay US map
  geom_sf(data = full_g1, aes(fill = Net_Price)) +
  scale_fill_viridis_c(option = "F") +
  labs(title = "Panel 2: Logged Net Price")


plot3<-ggplot() +
  geom_sf(data = us_map, fill = "white", color = "black") +  # Underlay US map
  geom_sf(data = full_g1, aes(fill = Tuition)) +
  scale_fill_viridis_c(option = "F") +
  labs(title = "Panel 2: Logged Tuition")



combined_plot <- plot_grid(plot1, plot2, plot3, ncol = 1, align = "v")

ggsave("combined_plot_national.png", combined_plot, width = 10, height = 8)


  

  