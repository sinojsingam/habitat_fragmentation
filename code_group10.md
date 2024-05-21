# Deforestation induced habitat fragmentation analysis
## Scripts used for the different steps
###### Authors: Sinoj Kokulasingam & Maëlle Dupont (Group 10) 
###### Under the theme "Tropical Deforestation" 

The scripts below describe the three different languages that were used for image acquisition, classification, image rectification, validation analysis using grid of points and finally obtaining fragmentation extent. The languages used for the analysis was JavaScript, Python and R/Rstudio.

## Step 0: Imports and GlobCover
In total, 7 imports were used:
 - The region of interest "roi" (.shp file) which was delineated with QGIS.

 - USGS Landsat 5 Level 2, Collection 2, Tier 1
    ```javascript
    var l5 = ee.ImageCollection("LANDSAT/LT05/C02/T1_L2")
    ```
 - ESA and UCLouvain GlobCover: Global Land Cover Map
     ```javascript
    ee.Image("ESA/GLOBCOVER_L4_200901_200912_V2_3")
    ```
 - Geometry objects for classification created in the Google Earth Engine platform for each year.
    - Water
    - Forest
    - Cropland
    - Bare soil

Due to the inability to conduct on-site visits in Bolivia and the coarse resolution of Landsat satellite images, we utilized Globcover to identify the necessary land cover classes for our study.
```javascript
var landcover = globCover.select('landcover').clip(roi);
var colorMap = {
  11:'aaefef',	//Post-flooding or irrigated croplands
  14:'ffff63',	//Rainfed croplands
  20:'dcef63',	//Mosaic cropland (50-70%) / vegetation (grassland, shrubland, forest) (20-50%)
  30:'cdcd64',	//Mosaic vegetation (grassland, shrubland, forest) (50-70%) / cropland (20-50%)
  40:'006300',	//Closed to open (>15%) broadleaved evergreen and/or semi-deciduous forest (>5m)
  50:'009f00',	//Closed (>40%) broadleaved deciduous forest (>5m)
  60:'aac700',	//Open (15-40%) broadleaved deciduous forest (>5m)
  70:'003b00',	//Closed (>40%) needleleaved evergreen forest (>5m)
  90:'286300',	//Open (15-40%) needleleaved deciduous or evergreen forest (>5m)
  100:'788300',	//Closed to open (>15%) mixed broadleaved and needleleaved forest (>5m)
  110:'8d9f00',	//Mosaic forest-shrubland (50-70%) / grassland (20-50%)
  120:'bd9500',	//Mosaic grassland (50-70%) / forest-shrubland (20-50%)
  130:'956300',	//Closed to open (>15%) shrubland (<5m)
  140:'ffb431',	//Closed to open (>15%) grassland
  150:'ffebae',	//Sparse (>15%) vegetation (woody vegetation, shrubs, grassland)
  160:'00785a',	//Closed (>40%) broadleaved forest regularly flooded - Fresh water
  170:'009578',	//Closed (>40%) broadleaved semi-deciduous and/or evergreen forest regularly flooded - saline water
  180:'00dc83',	//Closed to open (>15%) vegetation (grassland, shrubland, woody vegetation) on regularly flooded or waterlogged soil - fresh, brackish or saline water
  190:'c31300',	//Artificial surfaces and associated areas (urban areas >50%) GLOBCOVER 2009
  200:'fff5d6',	//Bare areas
  210:'0046c7',	//Water bodies
  220:'ffffff',	//Permanent snow and ice
  230:'743411' //unclassified
};
var maxValue = Math.max.apply(null, Object.keys(colorMap));
var array = Array.apply(null, Array(maxValue + 1))
  .map(function() { return '000000' });
Object.keys(colorMap).forEach(function (i) {
  array[i] = colorMap[i];
});
var palette = array.join(',');
var CovervisParams = {min: 0, max: maxValue, palette: palette};

```
## Step 1: Image Acquisition

In this step, Google Earth Engine was used to acquire the images for the different years. Preprocessing steps, such as cloud masking, clipping and compositing were also done in this step.

The following code retrieves images from a single summer season within a year, performs a cleanup process on them, and then combines them into a composite.

```javascript
//change for next year
var YEAR = '2005';
//date de debut: you only have to change YEAR
var startDate = YEAR+'-05-01'; 
//date de fin
var endDate = YEAR+'-08-30';

// Applies scaling factors for L5 images
function applyScaleFactors(image) {
  var opticalBands = image.select('SR_B.').multiply(0.0000275).add(-0.2);
  var thermalBand = image.select('ST_B.*').multiply(0.00341802).add(149.0);
  return image.addBands(opticalBands, null, true)
              .addBands(thermalBand, null, true);
}
// Mask clouds
function maskClouds(image) {
  var qaBand = image.select('QA_PIXEL');
  // Bits 3 and 4 are clouds and shadow
  var cloudBitMask = 1 << 3;
  var cloudShadowBitMask = 1 << 4;
  // masking clouds and their shadow
  var mask = qaBand.bitwiseAnd(cloudBitMask).eq(0)
                .and(qaBand.bitwiseAnd(cloudShadowBitMask).eq(0));
  // Return the image with the mask applied.
  return image.updateMask(mask);
}

//roi signifie région d'intérêt (San javier, Bolivia)
Map.centerObject(roi);

/* Obtenir des images */
var IMG = l5 //You have to change it to l8 if you want images after 2013
          //filter by date range
          .filterDate(startDate, endDate)
          // Filter by area of interest
          .filterBounds(roi)
          //mask clouds
          .map(maskClouds)
          //scale digital number
          .map(applyScaleFactors)
          //filter by cloud cover (<10%)
          .filter(ee.Filter.lt('CLOUD_COVER', 10))
          //compositing monthly data for cloudless image
          .mean()
          //clipping to small study area
          .clip(roi);

```
## Step 2: Classification
Classification was also done with Google Earth Engine with the Random Forests classifier.
The geometry objects were used to delineate ca. 15 polygons per class in the interactive map. They were later merged and used as training and test data for the classifier.

```javascript
/*
Training data nomenclature:

water: label 1
forest: label 2
cropland: label 3
bare_soil: label 4

*/
//train the model
var training_polygons = water
                      .merge(forest)
                      .merge(cropland)
                      .merge(bare_soil);

var bandsForTraining = ['SR_B1','SR_B2','SR_B3','SR_B4','SR_B5','SR_B7'];

var training = IMG.select(bandsForTraining).sampleRegions({
  collection: training_polygons, //polygons
  properties: ['label'],
  scale: 30
});

//split data to training and validation
var sample = training.randomColumn();
var split = 0.7;  // Roughly 70% training, 30% testing.
var trainingSample = sample.filter(ee.Filter.lt('random', split));
var validationSample = sample.filter(ee.Filter.gte('random', split));

//train the classifier
var trainedClassifier = ee.Classifier.smileRandomForest(10)
    .train({
      features: trainingSample,
      classProperty: 'label',
      inputProperties: bandsForTraining
    });

// Get information about the trained classifier.
print('Results of trained classifier', trainedClassifier.explain());

// Get a confusion matrix and overall accuracy for the training sample.
var trainAccuracy = trainedClassifier.confusionMatrix();
print('Training error matrix', trainAccuracy);
print('Training overall accuracy', trainAccuracy.accuracy());

// Get a confusion matrix and overall accuracy for the validation sample.
validationSample = validationSample.classify(trainedClassifier);
var validationAccuracy = validationSample.errorMatrix('label', 'classification');
print('Validation error matrix', validationAccuracy);
print('Validation accuracy', validationAccuracy.accuracy());

//classify images
var classified_image = IMG.classify(trainedClassifier);

```

Finally, the result and the satellite image could be visualized to evaluate if any further tweaking is needed.

```javascript
var true_colorL5 = ['SR_B3','SR_B2','SR_B1'];
var ndvi_colorL5 = ['SR_B4','SR_B3','SR_B1'];
var NIR_colorL5 = ['SR_B2','SR_B3','SR_B4'];
var swir_colorL5 = ['SR_B5','SR_B4','SR_B3'];


var visParams = {
                  bands:swir_colorL5,
                  min: 0, max: 0.3
                };
                
var visParamsNDVI = {
                  bands:ndvi_colorL5,
                  min: 0, max: 0.3
                };

var visParamsTrueColor = {
                  bands:true_colorL5,
                  min: 0, max: 0.3
                };
        
//show ndvi false color composite
Map.addLayer(IMG, visParamsNDVI, 'NDVI color');
//show shortwave infra-red false color composite
Map.addLayer(IMG, visParams, 'SWIR color');

//colors for the 4 classes
var colours=['#3d6bbf',
        '#348726',
        '#c9be22',
        '#fff024'];
//show classification
Map.addLayer(classified_image,
             {min:1, 
             max:4,
             palette: 
             colours,
             },
             'Classified image', false);

```
Lastly, we saved the images from Google's servers to our personal drives one by one to further process them.

``` javascript
//Specify export parameters
var scale = 30; //L5 resolution
var fileFormat = 'GeoTIFF'; // .tif
var fileNamePrefix = 'cls_'+YEAR; // Name for the exported file
//Export the raster
Export.image.toDrive({
  image: classified_image,
  description: fileNamePrefix,
  scale: scale,
  region: roi,
  fileFormat: fileFormat,
});
```
## Step 3: Process the classified images
After downloading the images (file named as classification_YEAR), they were reprojected from WGS84 to UTM zone 20S. The reprojected images were reclassified to binary maps representing forest and non-forest classes and lastly de-noised using a moving window filter.
```python
#imports
#conda env was used
import rasterio
import fiona
from rasterio import Affine as A
from rasterio.warp import calculate_default_transform, reproject, Resampling
import rasterio.features
import geopandas as gpd
from shapely.geometry import shape
import numpy as np
import math
import sys

year = sys.argv[1] # CLI

# Specifying the paths
raster_path = f"../classification/raw_classified/classification{year}.tif"
reproj_path = f"../classification/reprojected/reproject_{year}.tif"
vector_path = f"../classification/vectorized/vector_{year}.geojson"
reclassif_filter_tif = f"../classification/reclassified/reclassif_filter_{year}.tif"
#UTM South 327 + 20 = 32720 (note: UTM North is 326 + zone...) (UTM 20S Bolivia)
dst_crs = 'EPSG:32720'

# Reading the raster file
with rasterio.open(raster_path) as src:
    #Get the metadata of the source raster and update with new CRS
    transform, width, height = calculate_default_transform(
        src.crs, dst_crs, src.width, src.height, *src.bounds)
    kwargs = src.meta.copy()
    kwargs.update({
        'crs': dst_crs, #new CRS
        'transform': transform,
        'width': width,
        'height': height,
        'dtype': 'int16'
    })
    #Reprojecting the source raster to the new CRS
    with rasterio.open(reproj_path, 'w', **kwargs) as dst:
        for i in range(1, src.count + 1):
            data = rasterio.band(src, i)
            reproject(
                source=data,
                destination=rasterio.band(dst, i),
                src_transform=src.transform,
                src_crs=src.crs,
                dst_transform=transform,
                dst_crs=dst_crs,
                resampling=Resampling.nearest)


    # Reclassify the reprojected raster files
    with rasterio.open(reproj_path, 'r+') as src:
        # Read the raster data
        raster = src.read(1)
        #reclassify agriculture to non-forest
        raster = np.where(raster == 3, 1, raster)
        #reclassify bare soil to non-forest
        raster = np.where(raster == 4, 1, raster) 
        # Write the modified raster data back to the file
        src.write(raster, 1)
        # Set the nodata value to 0
        # This is important since the window filter throws an error if there are nan values
        raster[np.isnan(raster)] = 0
        # Make sure the data type is int16
        raster = raster.astype('int16')

        # Moving window filter (TP session)
        ws = 3 # Must be a odd number 3x3
        sizey = raster.shape[0]
        sizex = raster.shape[1]

        rad_wind = math.floor(ws/2)

        X = np.pad(raster, ((rad_wind,rad_wind),(rad_wind,rad_wind)), 'edge')

        majority = np.empty((sizey,sizex), dtype='int16')
        
        for i in range(sizey):
            for j in range(sizex):
                window = X[i:i+ws , j:j+ws]
                window = window.flatten()
                counts = np.bincount(window).astype(int)
                maj = np.argmax(counts)
                majority[i,j]= maj

        majority = majority.reshape((1,sizey,sizex))
        # Write the majority filter raster data to new file
        with rasterio.open(reproj_path) as src:
            profile = src.profile

        with rasterio.open(reclassif_filter_tif, "w", **profile) as dst:
            dst.write(majority)
```

The above code was saved as process_imgs.py and is run one year at a time using the terminal. For example:

```bash
python3 process_imgs.py 2010
```
## Step 4a: Validation using grid points
A grid of points spaced 1 kilometer apart was generated with an integer attribute called "deforestation" with the help of QGIS built-in tools. The grid was overlaid on each satellite image, followed by a visual interpretation of when deforestation took place in the location of each point. If deforestation occured at the points' location, the year is noted down in the deforestation column, if deforestation never took place at the location of that point then a 0 value is denoted.

## Step 4b: Calculation of accuracy
The script below would store the value of the classification at the point of each point, then perform accuracy analysis between the predicted value and the true values obtained from [Step 4a](#step-4a-validation-using-grid-points). We retain the fid column, in order to visually check in QGIS if the validation code was working properly.

```python
#imports
import rasterio
import fiona
from rasterio import Affine as A
from rasterio.warp import calculate_default_transform, reproject, Resampling
import rasterio.features
import geopandas as gpd
from shapely.geometry import shape
import numpy as np
import pandas as pd
import math
import matplotlib as mpl
import matplotlib.pyplot as plt
from sklearn.metrics import accuracy_score

#import grid of points
gdf = gpd.read_file('../points_defor/points_grid.shp')
years = [2005,2006,2007,2008,2009,2010,2011]

# Function for checking what is the classification at a point location
def check_point(row):
    # Get the row and column of the point in the raster
    row, col = src.index(row.geometry.x, row.geometry.y)
    
    # Check if the point overlays a pixel of 1
    if raster_array[row, col] == 1:
        return True
    else:
        return False
for year in years:
    image = f"../classification/reclassified/reclassif_filter_{year}.tif"
    #read the image for that year
    with rasterio.open(image) as src:
        raster_array = src.read(1)
    #add a column overlays_* that has the data for which if it was classified as deforested or not (predicted column)
    gdf[f'overlays_{year}'] = gdf.apply(check_point, axis=1)

#reduce the gdf to have only the necessary columns (could be skipped)
validation =  gdf.iloc[:, 8:]
#get the predicted columns
overlays_columns = validation.filter(like='overlays_')
# Concatenate just what is needed, then later it could be joined using the fid
# validation['deforestat'] has the real values

df = pd.concat([gdf['fid'],validation['deforestat'], overlays_columns], axis=1)
#fid needs to be an integer to be able to save as gpkg later
df['fid'] = df['fid'].astype(int)
#get the predicted columns
overlays = df.filter(like='overlays_')
#remap the predicted columns from True and False to 0 and 1 respectively.
df[overlays.columns] = overlays.map(lambda x: 1 if x else 0)
```
Iterate over each year and generate a new column (true_YEAR), which is filled with either 1s or 0s. The values depend on the year and the deforestat value. For instance, if the current iteration is for the year 2009 and the deforestat value is 2011, then the row will be assigned a 1, otherwise it will be assigned a 0. These values will serve as the true values for the confusion matrix.

```python
for year in years:
    df[f'true_{year}'] = df['deforestat'].apply(lambda x: 1 if x <= year and x != 0 else 0)
# Dictionary to store the accuracies
accuracy_dict = {}
for year in years:
    y_true = df[f'true_{year}']
    y_pred = df[f'overlays_{year}']
    acc = accuracy_score(y_true, y_pred)
    #populate the dict
    accuracy_dict[year] = acc

# Plot bar graph using plt
mpl.rc('font', family='Arial')
mpl.rc('xtick', labelcolor='#4D4D4D')
mpl.rc('ytick', labelcolor='#4D4D4D')

fig, ax = plt.subplots()

ax.bar(accuracy_dict.keys(), accuracy_dict.values(), color='#BA55D3',width=0.3)
plt.xlabel('Year', color='#4D4D4D')
plt.ylabel('Accuracy', color='#4D4D4D')
plt.title('Accuracy for each year', color='#4D4D4D')
#set color for the graph borders
for spine in ax.spines.values():
    spine.set_color('#4D4D4D')
#set color for axis ticks
ax.tick_params(colors='#4D4D4D')
#save accuracy figure as png
plt.savefig('accuracy.png', transparent=True)

```
## Step 5: Calculate fragmentation indices
The fragmentation of each image is assessed using the landscapemetric library in R. Three functions were used, namely the Shannon's diversity index at the landscape level, the patch density and the mean contiguity of the non-forest class.

```R
#import libraries
library(terra)
library(landscapemetrics)
library(raster)
library(ggplot2)
library(gridExtra)
library(dplyr)

#set directory path where the reclassified cleaned images are located
path = "classification/reclassified/"
#convert to raster object
#remove values of 0 (border pixels that are not any class but appeared after reprojection)
raster_2005 <- raster(paste(path,"reclassif_filter_2005.tif", sep = ""))
raster_2005[raster_2005==0] <- NA

raster_2006 <- raster(paste(path,"reclassif_filter_2006.tif", sep = ""))
raster_2006[raster_2006==0] <- NA

raster_2007 <- raster(paste(path,"reclassif_filter_2007.tif", sep = ""))
raster_2007[raster_2007==0] <- NA

raster_2008 <- raster(paste(path,"reclassif_filter_2008.tif", sep = ""))
raster_2008[raster_2008==0] <- NA

raster_2009 <- raster(paste(path,"reclassif_filter_2009.tif", sep = ""))
raster_2009[raster_2009==0] <- NA

raster_2010 <- raster(paste(path,"reclassif_filter_2010.tif", sep = ""))
raster_2010[raster_2010==0] <- NA

raster_2011 <- raster(paste(path,"reclassif_filter_2011.tif", sep = ""))
raster_2011[raster_2011==0] <- NA

#group all the rasters
liste_rasters <- list(raster_2005, raster_2006, raster_2007, raster_2008, raster_2009, raster_2010, raster_2011)

#apply landscapemetrics functions on the raster group
#lapply returns multiple individual tibbles
list_shdi <- lapply(liste_rasters, lsm_l_shdi)
#concatenate all the tibbles into one table
table_shdi <- do.call(rbind, list_shdi)

years <- c("2005", "2006", "2007", "2008", "2009", "2010", "2011")
#repreated years since there are 2 classes
years_repeated <-  rep(c("2005", "2006", "2007", "2008", "2009", "2010", "2011"), each = 2)

#patch density
table_pd <- lapply(liste_rasters, lsm_c_pd)
table_pd <- do.call(rbind, table_pd)
table_pd$years <- years_repeated
#mean contiguity
table_contig = lapply(liste_rasters, lsm_c_contig_mn)
table_contig <- do.call(rbind, table_contig)

#get patch density and contiguity of just the nonforest areas
class_1_pd <- table_pd[table_pd$class == 1, ]
class_1_contig <- table_contig[table_contig$class == 1, ]
#add the years data
table_shdi$years <- years

#plot
plot_shdi <- ggplot() +
  geom_line( data = table_shdi, aes(x = years, y = value, color = "SHDI",group = 1)) +
  scale_color_manual(values = c("blue","darkblue","red",'green')) +
  labs(x = "Year", y = "Value") +
  theme_minimal() +  
  theme(axis.text.x = element_text(angle = 0, hjust = 1),  
        plot.title = element_text(hjust = 0.5),
        legend.title = element_blank(),
        legend.text = element_text(size = 12),
        legend.position = "bottom")

#add patch density to plot
plot_shdi <- plot_shdi +
  geom_line(data = class_1_pd, aes(x = years, y = value, color = "Patch density",group = 1)) +
  labs(color = NULL)
#add contiguity to plot
plot_shdi <- plot_shdi +
  geom_line(data = class_1_contig, aes(x = years, y = value, color = "Mean contiguity",group = 1)) +
  labs(color = NULL)

#display all graphs
plot_shdi

```
All cartographic products for this poster were done using QGIS version 3.36 (Maidenhead). We used Visual Studio Code and RStudio as our IDEs. Google Earth Engine was accessed through the interactive web page.
