library(here)
library(shiny)
library(shinythemes)
library(tidyverse)
library(sf)
library(scales)
library(plotly)
library(ggplot2)
library(ggrepel)
library(stringr)
library(viridis)
library(patchwork)
library(cowplot)


######################################################
# Load Data 
######################################################

###load data 

# Core data
load(here("data","cleaned","full_g_sub_2.Rdata"))
temp<-full_g%>%
  select(geoid, geometry)

load(here("data","cleaned","full_g_sub_2_ipeds.Rds")) 
full_g<-full_g%>%
  select(-geometry)

full_g<-full_g%>%
  mutate(log_wmeasure=log(wmeasure))

full_g<-pivot_wider(full_g, 
                    id_cols=c(geoid, msa_name), 
                    names_from=measure,
                    values_from=log_wmeasure)

full_g<-left_join(full_g,temp,by="geoid")

full_g1<-st_as_sf(full_g)


## Metro area polygons
acs_g <- readRDS(here("data","cleaned","acs_g_cbsa.Rds")) #note, this is msa-level, 5yr estimates

## Metro area points
acs_c <- readRDS(here("data","cleaned","acs_c_cbsa.Rds"))

#ipeds
ipeds<-readRDS(file=here("data","cleaned",paste0("institutions.Rds")))

ipeds<-ipeds%>%
  filter(sector%in%c(1,4))%>%
  select(instnm, longitud, latitude, unitid)

ipeds<-ipeds%>%rename(longitude=longitud)

ipeds_sf <- st_as_sf(ipeds, coords = c("longitude", "latitude"), crs = "NAD83")

ipeds_sf<-left_join(ipeds_sf,ipeds, by=c("unitid", "instnm"))


#####################################
# Create Map
######################################

###Filter by MSA
full_g1<-full_g1%>%
  filter(msa_name=="Philadelphia-Camden-Wilmington, PA-NJ-DE-MD")

full_g1<-full_g1%>%
  rename("Tuition"="tuit","Enrollment"="fteug","Net_Price"="net_price")

###Filter Ipeds 
ipeds_sf1<-st_join(ipeds_sf, full_g1, join = st_within, left=FALSE)

#replace long institution names
ipeds_sf1<-ipeds_sf1%>%
  mutate(instm=ifelse(instnm=="Rowan College at Burlington County","Rowan College (br)",instnm))%>%
  mutate(instnm=ifelse(instnm=="Rowan College of South Jersey Gloucester Campus","Rowan College (br)",instnm))%>%
  mutate(instnm=ifelse(instnm=="Rutgers University-Camden","Rutgers University (br)",instnm))%>%
  mutate(instnm=ifelse(instnm=="Pennsylvania State University-Penn State Great Valley","Penn State (br)",instnm))%>%
  mutate(instnm=ifelse(instnm=="Pennsylvania State University-Penn State Brandywine","Penn State (br)",instnm))%>%
  mutate(instnm=ifelse(instnm=="Pennsylvania State University-Penn State Abington","Penn State (br)",instnm))%>%
  mutate(instnm=ifelse(instnm=="West Chester University of Pennsylvania","West Chester University",instnm))
  

##map: Enrollment 

plot1<-ggplot() +
  geom_sf(data = full_g1, aes(fill = Enrollment), color = "black") +
  geom_sf(data = ipeds_sf1, color = "white", size = 1) +
  geom_text_repel(data = ipeds_sf1, aes(x = longitude, y = latitude, label = str_wrap(instnm, width = 15)), 
                  box.padding = 0.5, point.padding = 0.1, segment.color = "transparent",
                  size = 3, color = "white", fontface = "bold") +  
  scale_fill_viridis_c(option = "F", oob = scales::squish, trans = "reverse", name = "Logged Enrollment") +  # Reverse the color scale
  theme(panel.background = element_rect(fill = "darkgray")) +  # Set panel (plot area) background color
  xlab("") + ylab("")

ggsave("plot1.png", plot1, width = 10, height = 8)



##map: Net Price 

plot2<-ggplot() +
  geom_sf(data = full_g1, aes(fill = Net_Price), color = "black") +
  geom_sf(data = ipeds_sf1, color = "white", size = 1) +
  geom_text_repel(data = ipeds_sf1, aes(x = longitude, y = latitude, label = str_wrap(instnm, width = 15)), 
                  box.padding = 0.5, point.padding = 0.1, segment.color = "transparent",
                  size = 3, color = "white", fontface = "bold") +  
  scale_fill_viridis_c(option = "F", oob = scales::squish, name = "Logged Net Price") + 
  theme(panel.background = element_rect(fill = "darkgray")) +  # Set panel (plot area) background color
  xlab("") + ylab("")

ggsave("plot2.png", plot2, width = 10, height = 8)

##map: Tuition 
plot3<-ggplot() +
  geom_sf(data = full_g1, aes(fill = Tuition), color = "black") +
  geom_sf(data = ipeds_sf1, color = "white", size = 1) +
  geom_text_repel(data = ipeds_sf1, aes(x = longitude, y = latitude, label = str_wrap(instnm, width = 15)), 
                  box.padding = 0.5, point.padding = 0.1, segment.color = "transparent",
                  size = 3, color = "white", fontface = "bold") +  
  scale_fill_viridis_c(option = "F", oob = scales::squish, name = "Logged Tuition") + 
  theme(panel.background = element_rect(fill = "darkgray")) +  # Set panel (plot area) background color
  xlab("") + ylab("")

ggsave("plot3.png", plot3, width = 10, height = 8)


combined_plot <- plot_grid(plot1, plot2, plot3, ncol = 2, align = "v")

ggsave("combined_plot.png", combined_plot, width = 10, height = 8)






