library(ggplot2)
library(dplyr)

create_msa_plot <- function(msa_select_name, campus_type) {
  # Assuming you have a data frame 'full_g' with columns 'msa_name', 'peps_campuses', and geometry
  
  # Filter data based on msa_select_name
  filtered_g <- full_g %>%
    filter(str_detect(msa_name,msa_select_name))
  
  campus_type_col <- sym(campus_type) 
  
  # Create a plot
  p <- ggplot() +
    geom_sf(data=filtered_g)+
    geom_sf(data = filtered_g, aes(fill = !!campus_type_col)) +
    scale_fill_viridis_c()
  
  print(p)
}

# Example usage:
#create_msa_plot("Houston", "peps_campuses")
