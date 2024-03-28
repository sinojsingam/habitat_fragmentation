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

year = sys.argv[1] # Specify the year of the classification

# Specify the path to your raster file

raster_path = f"../classification/raw_classified/classification{year}.tif"
reproj_path = f"../classification/reprojected/reproject_{year}.tif"
vector_path = f"../classification/vectorized/vector_{year}.geojson"
reclassif_filter_tif = f"../classification/reclassified/reclassif_filter_{year}.tif"
#UTM South 327 + 20 = 32720 (UTM North 326...) (UTM 20S Bolivia)
dst_crs = 'EPSG:32720' # Specify the CRS of the output raster

# Open the raster file

with rasterio.open(raster_path) as src:
    transform, width, height = calculate_default_transform(
        src.crs, dst_crs, src.width, src.height, *src.bounds)
    #get the metadata of the source raster and update with new CRS
    kwargs = src.meta.copy()
    kwargs.update({
        'crs': dst_crs,
        'transform': transform,
        'width': width,
        'height': height,
        'dtype': 'int16'
    })

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



    with rasterio.open(reproj_path, 'r+') as src:
        # Read the raster data
        raster = src.read(1)

        # Assign labels 1, 3, 4 to 1
        raster = np.where((raster == 3) | (raster == 4), 1, raster)
        # Write the modified raster data back to the file
        src.write(raster, 1)

        raster[np.isnan(raster)] = 0
        raster = raster.astype('int16')
        ws = 3 # Must be a odd number 3x3, 5x5, 7x7, ... (filtering post classification)
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

        with rasterio.open(reproj_path) as src:
            profile = src.profile

        with rasterio.open(reclassif_filter_tif, "w", **profile) as dst:
            dst.write(majority)


# # Open the raster file
# with rasterio.open(reproj_path) as src:
#     # Read the raster data
#     raster = src.read(1)



# # Convert the raster to vector
# shapes = rasterio.features.shapes(raster, transform=src.transform)
# features = [{'geometry': shape(geom), 'label': value} for geom, value in shapes]

# # Create a GeoDataFrame
# gdf = gpd.GeoDataFrame(features, crs=src.crs,geometry='geometry')

# # Save the GeoDataFrame to a new file
# gdf.to_file(vector_path, driver='GeoJSON')