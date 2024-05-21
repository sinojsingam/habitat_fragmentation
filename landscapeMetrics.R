install.packages("landscapemetrics")
install.packages("sp")
install.packages("raster")

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
#plot(raster_2011)
plot(raster_2009)


# Aggregated clumpiness index (ACI)
liste_rasters <- list(raster_2005, raster_2006, raster_2007, raster_2008, raster_2009, raster_2010, raster_2011)  # Ajoutez vos rasters à la liste

landscape_2005 <- aggregate(raster_2005, fact = 1, fun = "sum")
landscape_2006 <- aggregate(raster_2006, fact = 1, fun = "sum")
landscape_2007 <- aggregate(raster_2007, fact = 1, fun = "sum")
landscape_2008 <- aggregate(raster_2008, fact = 1, fun = "sum")
landscape_2009 <- aggregate(raster_2009, fact = 1, fun = "sum")
landscape_2010 <- aggregate(raster_2010, fact = 1, fun = "sum")
landscape_2011 <- aggregate(raster_2011, fact = 1, fun = "sum")

liste_landscape <- list(landscape_2005, landscape_2006, landscape_2007, landscape_2008, landscape_2009, landscape_2010, landscape_2011)


#------------------------------------------GRAPH_01---------------------------------------------------------------
# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_ai <- lapply(liste_rasters, lsm_c_ed)

table_ai <- do.call(rbind, liste_ai)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_ai$years <- years

# Afficher le tableau
print(table_ai)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_ai <- table_ai[table_ai$class == 1, ]
class_2_ai <- table_ai[table_ai$class == 2, ]

#class_1_ai <- class_1_ai %>%
  #mutate(class = "No forest")

#class_2_ai <- class_2_ai %>%
  #mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_ai <- rbind(class_1_ai, class_2_ai)
class_labels <- c(rep("No Forest", nrow(class_1_ai)), rep("Forest", nrow(class_2_ai)))

plot_graph_ai <- ggplot(combined_data_ai, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Aggregation Index [%]", title = "Analyzing Dominant Patch Sizes Specifically within Forest and Non-Forest Land Use Classes") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.5) 

print(plot_graph_ai)
ggsave("Graphique_1_aggragation_index.png", plot_graph_ai,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_1_aggragation_index.pdf", plot_graph_ai, width = 10, height = 4)

#-------------------------------------------GRAPH_2------------------------------------------------------------
# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste

# Appliquer la fonction lsm_c_enn_mn à chaque landscape
liste_mn <- lapply(liste_landscape, lsm_c_enn_mn, directions = 8, verbose = TRUE)

table_mn <- do.call(rbind, liste_mn)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_mn$years <- years

# Afficher le tableau
print(table_mn)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_mn <- table_mn[table_mn$class == 1, ]
class_2_mn <- table_mn[table_mn$class == 2, ]

#class_1_mn <- class_1_ai %>%
#mutate(class = "No forest")

#class_2_mn <- class_2_ai %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_mn <- rbind(class_1_mn, class_2_mn)
class_labels <- c(rep("No Forest", nrow(class_1_mn)), rep("Forest", nrow(class_2_mn)))

plot_graph_mn <- ggplot(combined_data_mn, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Euclidean mean distance [m]", 
       title = "Comparative Analysis of Average Euclidean Distances\nbetween Neighboring Patches: Forest versus Non-Forest Land") + # Titre sur deux lignes
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), 
            position = position_dodge(width = 0.5), 
            vjust = -0.7,  # Élever les étiquettes au-dessus des barres
            size = 2,  # Ajuster la taille du texte
            fontface = "bold")  # Rendre le texte en gras

print(plot_graph_mn)
ggsave("Graphique_2_Euclidean_mean_distance.png", plot_graph_mn,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_2_Euclidean_mean_distance.pdf", plot_graph_mn, width = 10, height = 4)

#-----------------------------------------end for lsm_c_area_mn() fonction------------------------------------------

#-----------------------------------------GRAPH03----------------------------------------------------------
# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_ea <- lapply(liste_landscape, lsm_c_area_mn, directions = 8)

table_ea <- do.call(rbind, liste_ea)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_ea$years <- years

# Afficher le tableau
print(table_ea)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_ea <- table_ea[table_ea$class == 1, ]
class_2_ea <- table_ea[table_ea$class == 2, ]

#class_1_ea <- class_1_ea %>%
#mutate(class = "No forest")

#class_2_ea <- class_2_ea %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_ea <- rbind(class_1_ea, class_2_ea)
class_labels <- c(rep("No Forest", nrow(class_1_ea)), rep("Forest", nrow(class_2_ea)))

plot_graph_ea <- ggplot(combined_data_ea, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) + labs(x = "Year", y = "Mean patch area [Hectares]", 
      title = "Analyzing Landscape Composition: Average Patch Surface Comparison between Forested and Non-Forested Areas") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_ea)
ggsave("Graphique_3_Average Patch Surface.png", plot_graph_ea,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_3_Average Patch Surface.pdf", plot_graph_ea, width = 10, height = 4)


#---------------------------------end of lsm_c_area_mn() fonction --------------------------------------------

#----------------------------------------GRAPH04 lsm_c_core_mn()----------------------------------------------

# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_re <- lapply(liste_rasters, lsm_c_core_mn)

table_re <- do.call(rbind, liste_re)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_re$years <- years

# Afficher le tableau
print(table_re)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_re <- table_re[table_re$class == 1, ]
class_2_re <- table_re[table_re$class == 2, ]

#class_1_re <- class_1_re %>%
#mutate(class = "No forest")

#class_2_re <- class_2_re %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_re <- rbind(class_1_re, class_2_re)
class_labels <- c(rep("No Forest", nrow(class_1_re)), rep("Forest", nrow(class_2_re)))

plot_graph_re <- ggplot(combined_data_re, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Mean of core area [Hectares]", title = "Trend of mean core area by year") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_re)
ggsave("Graphique_4_Mean of core area.png", plot_graph_re,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_4_Mean of core area.pdf", plot_graph_re, width = 10, height = 4)

#---------------------------------end of the Graph with lsm_c_core_mn fonction ---------------------------------



#--------------------------------------------------GRAPH05-------------------------------------------------

# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_pd <- lapply(liste_landscape, lsm_c_pd)

table_pd <- do.call(rbind, liste_pd)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_pd$years <- years

# Afficher le tableau
print(table_pd)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_pd <- table_pd[table_pd$class == 1, ]
class_2_pd <- table_pd[table_pd$class == 2, ]

#class_1_pd <- class_1_pd %>%
#mutate(class = "No forest")

#class_2_pd <- class_2_pd %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_pd <- rbind(class_1_pd, class_2_pd)
class_labels <- c(rep("No Forest", nrow(class_1_pd)), rep("Forest", nrow(class_2_pd)))

plot_graph_pd <- ggplot(combined_data_pd, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Patch density", title = "Assessing Land Use Class Fragmentation: Patch Density Metric for Forest and Non-Forest Areas") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_pd)
ggsave("Graphique_5_Patch density.png", plot_graph_pd,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_5_Patch density.pdf", plot_graph_pd, width = 10, height = 4)


#-----------------------------------------end of lsm_c_pd() graph---------------------------------------------


#------------------------------------------------GRAPH06 lsm_c_pland-----------------------------------------------------------


# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_nd <- lapply(liste_landscape, lsm_c_pland, directions = 8)

table_nd <- do.call(rbind, liste_nd)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_nd$years <- years

# Afficher le tableau
print(table_nd)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_nd <- table_nd[table_nd$class == 1, ]
class_2_nd <- table_nd[table_nd$class == 2, ]

#class_1_pd <- class_1_pd %>%
#mutate(class = "No forest")

#class_2_pd <- class_2_pd %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_nd <- rbind(class_1_nd, class_2_nd)
class_labels <- c(rep("No Forest", nrow(class_1_nd)), rep("Forest", nrow(class_2_nd)))

plot_graph_nd <- ggplot(combined_data_nd, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Percentage of landscape of class [%]", title = "Comparative Analysis of Forest and Non-Forest Landscape Composition Percentages") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_nd)
ggsave("Graphique_6_Percentage_of_landscape of class.png", plot_graph_nd,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_6_Percentage_of_landscape of class.pdf", plot_graph_nd, width = 10, height = 4)



#---------------------------------------------end of lsm_c_pland--------------------------------------------

#------------------------------------------------GRAPH07 lsm_c_np-----------------------------------------------------------

# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_np <- lapply(liste_landscape, lsm_c_np, directions = 8)

table_np <- do.call(rbind, liste_np)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_np$years <- years

# Afficher le tableau
print(table_np)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_np <- table_np[table_np$class == 1, ]
class_2_np <- table_np[table_np$class == 2, ]

#class_1_pd <- class_1_pd %>%
#mutate(class = "No forest")

#class_2_pd <- class_2_pd %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_np <- rbind(class_1_np, class_2_np)
class_labels <- c(rep("No Forest", nrow(class_1_np)), rep("Forest", nrow(class_2_np)))

plot_graph_np <- ggplot(combined_data_np, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Number of Patches [/]", title = "Landscape Class Fragmentation Analysis of Forest and Non-Forest") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "Non-Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_np)
ggsave("Graphique_7_Percentage_of_landscape of class.png", plot_graph_np,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_7_Percentage_of_landscape of class.pdf", plot_graph_np, width = 10, height = 4)

#---------------------------------------------end of lsm_c_np--------------------------------------------

#------------------------------------------------GRAPH08 lsm_c_ca-----------------------------------------------------------

# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_ca <- lapply(liste_landscape, lsm_c_ca, directions = 8)

table_ca <- do.call(rbind, liste_ca)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_ca$years <- years

# Afficher le tableau
print(table_ca)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_ca <- table_ca[table_ca$class == 1, ]
class_2_ca <- table_ca[table_ca$class == 2, ]

# Combiner les deux jeux de données
combined_data_ca <- rbind(class_1_ca, class_2_ca)
class_labels <- c(rep("No Forest", nrow(class_1_ca)), rep("Forest", nrow(class_2_ca)))

plot_graph_ca <- ggplot(combined_data_ca, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Total Area by Class [Hectares]", title = "Comparative Analysis of Landscape Composition Using Total Class Area of Forest and Non-Forest") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "Non-Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_ca)
ggsave("Graphique_8_Percentage_of_landscape of class.png", plot_graph_ca,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_8_Percentage_of_landscape of class.pdf", plot_graph_ca, width = 10, height = 4)




#new_graph with only Non-forest

ggplot(class_1_ca, aes(x= years, y= value)) + 
  geom_bar(stat="identity", fill="lavender") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") +
  scale_fill_manual(values = c("No Forest" = "lavender"),
                    labels = c("Non-Forest")) +  
  geom_text(aes(label = round(value, 1)), position = position_dodge(width = 0.5), vjust = -0.5, 
          size = 2.0)
ggplot(class_1_ca, aes(x = years, y = value, fill = "Non-Forest")) + 
  geom_bar(stat = "identity", position = "dodge", colour = "black", size = 0.1) +  # Ajout d'un contour noir pour distinguer les barres
  geom_text(aes(label = round(value, 1)), position = position_dodge(width = 0.5), vjust = -0.5, size = 3.5) +  # Ajustement du texte
  scale_fill_manual(values = c("Non-Forest" = "lavender"), labels = c("Non-Forest Area")) +  # Clarification de la légende
  labs(title = "Analysis of Values Over Years", 
       x = "Year", 
       y = "Value",
       fill = "Area Type") +  # Ajout des titres des axes et de la légende
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),  # Rotation des étiquettes de l'axe x pour améliorer la lisibilité
        plot.title = element_text(hjust = 0.5, size = 16),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom",
        plot.margin = margin(1, 1, 1, 1, "cm"))  # Ajustement des marges pour une meilleure présentation




print(plot_graph_ca)
ggsave("Graphique_8_Percentage_of_landscape of class.png", plot_graph_ca,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_8_Percentage_of_landscape of class.pdf", plot_graph_ca, width = 10, height = 4)

#---------------------------------------------end of lsm_c_ca--------------------------------------------

#------------------------------------------------GRAPH09 lsm_c_lpi-----------------------------------------------------------

# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_lpi <- lapply(liste_landscape, lsm_c_lpi, directions = 8)

table_lpi <- do.call(rbind, liste_lpi)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_lpi$years <- years

# Afficher le tableau
print(table_lpi)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_lpi <- table_lpi[table_lpi$class == 1, ]
class_2_lpi <- table_lpi[table_lpi$class == 2, ]

#class_1_pd <- class_1_pd %>%
#mutate(class = "No forest")

#class_2_pd <- class_2_pd %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_lpi <- rbind(class_1_lpi, class_2_lpi)
class_labels <- c(rep("No Forest", nrow(class_1_lpi)), rep("Forest", nrow(class_2_lpi)))

plot_graph_lpi <- ggplot(combined_data_lpi, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Percentage of Landscape Covered by Forest or Non-Forest [%]", title = "Impact of Fragmentation on Largest Patch Index in Forested vs Non-Forested Landscapes") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "Non-Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_lpi)
ggsave("Graphique_9.png", plot_graph_lpi,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_9.pdf", plot_graph_lpi, width = 10, height = 4)

#---------------------------------------------end of lsm_c_ca--------------------------------------------

liste_ig <- lapply(liste_landscape, lsm_c_contig_mn, directions = 8)

table_ig <- do.call(rbind, liste_ig)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_ig$years <- years

# Afficher le tableau
print(table_ig)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_ig <- table_ig[table_ig$class == 1, ]
class_2_ig <- table_ig[table_ig$class == 2, ]

#class_1_pd <- class_1_pd %>%
#mutate(class = "No forest")

#class_2_pd <- class_2_pd %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_ig <- rbind(class_1_ig, class_2_ig)
class_labels <- c(rep("No Forest", nrow(class_1_ig)), rep("Forest", nrow(class_2_ig)))

plot_graph_ig <- ggplot(combined_data_ig, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Percentage of Landscape Covered by Forest or Non-Forest [%]", title = "Impact of Fragmentation on Largest Patch Index in Forested vs Non-Forested Landscapes") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "Non-Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_ig)
ggsave("Graphique_10.png", plot_graph_lpi,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_10.pdf", plot_graph_lpi, width = 10, height = 4)




forest_binary_2010= raster_2010>1
metrics_2010 <- calculate_lsm(forest_binary_2010, what = c("patch.number", "area.mn", "edge.density", "shape.index", "core.area"), res = res(forest_binary_2010))

forest_binary_2011= raster_2011>1
metrics_2011 <- calculaite_lsm(forest_binary_2011, what = c("patch.number", "area.mn", "edge.density", "shape.index", "core.area"), res = res(forest_binary_2011))

combined = rbind(metrics_2010,metrics_2011)
print(combined)













































#POUBELLE

#------------------------------------------------GRAPH10 lsm_p_area-----------------------------------------------------------

# Appliquer lsm_c_ai() à chaque raster dans la liste et stocker les résultats dans une liste
liste_area <- lapply(liste_landscape, lsm_p_area, directions = 8)

table_area <- do.call(rbind, liste_area)
years <- rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)  # Répétez chaque année deux fois
table_area$years <- rep(years, length.out = 7886)


# Afficher le tableau
print(table_area)

# Sélectionner les lignes où la valeur dans 'Colonne1' est égale à 10
class_1_area <- table_area[table_area$class == 1, ]
class_2_area <- table_area[table_area$class == 2, ]

#class_1_pd <- class_1_pd %>%
#mutate(class = "No forest")

#class_2_pd <- class_2_pd %>%
#mutate(class = "Forest")

# Combiner les deux jeux de données
combined_data_area <- rbind(class_1_area, class_2_area)
class_labels <- c(rep("No Forest", nrow(class_1_area)), rep("Forest", nrow(class_2_area)))

plot_graph_area <- ggplot(combined_data_area, aes(x = years, y = value, fill = factor(class_labels))) +
  geom_bar(stat = "identity", position = "dodge", color = "black", width = 0.5) +  
  labs(x = "Year", y = "Percentage of Landscape Covered by Forest or Non-Forest [%]", title = "Impact of Fragmentation on Largest Patch Index in Forested vs Non-Forested Landscapes") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_fill_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                    labels = c("Forest", "Non-Forest")) +  
  geom_text(aes(label = round(value, 2)), position = position_dodge(width = 0.5), vjust = -0.5, 
            size = 2.0) 

print(plot_graph_area)
ggsave("Graphique_10.png", plot_graph_area,width = 10, height = 4, units = "in", dpi = 600)
ggsave("Graphique_10.pdf", plot_graph_area, width = 10, height = 4)



help(package = "landscapemetrics")



## a voir
plot_graph_mn <- ggplot(combined_data_mn, aes(x = years, y = value, color = factor(class_labels))) +
  geom_point(size = 3) +  # Utiliser geom_point pour un scatter plot
  labs(x = "Year", y = "Euclidean mean distance", title = "Mean of euclidean nearest-neighbor distance") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom") + 
  scale_color_manual(values = c("Forest" = "papayawhip", "No Forest" = "lavender"),
                     labels = c("Forest", "No Forest")) +  
  geom_text(aes(label = round(value, 2)), vjust = -0.5, size = 3)  # Ajouter les labels avec geom_text

print(plot_graph_mn)

