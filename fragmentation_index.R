library(terra)
library(landscapemetrics)
library(raster)
library(ggplot2)
library(gridExtra)
library(dplyr)

path = "classification/reclassified/"
raster_2005 <- raster(paste(path,"reclassif_filter_2005.tif", sep = ""))
raster_2005[raster_2005==0] <- NA


raster_2006 <- raster(paste(path,"reclassif_filter_2006.tif", sep = ""))
raster_2006[raster_2006==0] <- NA
#plot(raster_2006)

raster_2007 <- raster(paste(path,"reclassif_filter_2007.tif", sep = ""))
raster_2007[raster_2007==0] <- NA
#plot(raster_2007)

raster_2008 <- raster(paste(path,"reclassif_filter_2008.tif", sep = ""))
raster_2008[raster_2008==0] <- NA
#plot(raster_2008)

raster_2009 <- raster(paste(path,"reclassif_filter_2009.tif", sep = ""))
raster_2009[raster_2009==0] <- NA
#plot(raster_2009)

raster_2010 <- raster(paste(path,"reclassif_filter_2010.tif", sep = ""))
raster_2010[raster_2010==0] <- NA
#plot(raster_2010)

raster_2011 <- raster(paste(path,"reclassif_filter_2011.tif", sep = ""))
raster_2011[raster_2011==0] <- NA
liste_rasters <- list(raster_2005, raster_2006, raster_2007, raster_2008, raster_2009, raster_2010, raster_2011)  # Ajoutez vos rasters à la liste

#plot(raster_2011)
#show_patches(raster_2011)

lsm_c_ed(raster_2009)



# Get the cell area
cell_area <- prod(res(raster_2011))

# Get the number of cells in the raster
num_cells <- ncell(raster_2011)

# Calculate the total area
total_area <- cell_area * num_cells

# Print the total area
lsm_c_pd(raster_2011)
lsm_l_ed(raster_2011)
lsm_c_pland(raster_2011)
lsm_c_enn_mn(raster_2011)
lsm_l_shdi(raster_2011)
lsm_l_lsi(raster_2005)
lsm_l_shei(raster_2005)
lsm_c_cai_mn(raster_2011)
lsm_l_split(raster_2005, directions = 8)
lsm_c_contig_mn(raster_2011)
liste_ai <- lapply(liste_rasters, lsm_l_shdi)
list_ed = lapply(liste_rasters, lsm_l_ed)
table_ed <- do.call(rbind, list_ed)
table_ai <- do.call(rbind, liste_ai)

years <- c("2005", "2006", "2007", "2008", "2009", "2010", "2011")
years_repeated <-  rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)

table_ai$years <- years
table_ed$years <- years

plot_graph_ai = ggplot() +
  geom_line( data = table_ai, aes(x = years, y = value, color = "SHDI",group = 1)) +
  scale_color_manual(values = c("blue","darkblue","red",'green')) +
  labs(x = "Year", y = "Value") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom")


table_pd = lapply(liste_rasters, lsm_c_pd)
table_pd <- do.call(rbind, table_pd)
table_pd$years <- years_repeated
table_contig = lapply(liste_rasters, lsm_c_contig_mn)
table_contig <- do.call(rbind, table_contig)
class_1_pd <- table_pd[table_pd$class == 1, ]
class_1_contig <- table_contig[table_contig$class == 1, ]

plot_graph_ai <- plot_graph_ai +
  geom_line(data = class_1_pd, aes(x = years, y = value, color = "Patch density",group = 1)) +
  labs(color = NULL)

plot_graph_ai <- plot_graph_ai +
  geom_line(data = class_1_contig, aes(x = years, y = value, color = "Mean contiguity",group = 1)) +
  labs(color = NULL)

# plot_graph_ai <- plot_graph_ai + 
#   geom_line(data = table_ed, aes(x = years, y = value, color = "Edge density",group=1)) +  # Example for adding a line  # Specify the color of the line
#   labs(color = NULL) +  # Optional: Remove legend title for color aesthetics
#   scale_y_continuous(sec.axis = sec_axis(~.*coeff, name = "Area (m/ha)"))  # Add secondary y-axis


plot_graph_ai
