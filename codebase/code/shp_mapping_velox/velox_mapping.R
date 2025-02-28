library(velox)
library(raster)
library(sf)

setwd("/gpfs/data/fs71391/cschmidt/lenian/projects/attaino3/repos/attain_paper/code/shp_mapping_velox")
mda_f <- list.files("/gpfs/data/fs71391/cschmidt/lenian/data/attain/model_output/",full.names = TRUE)
mda_files <- list.files("/gpfs/data/fs71391/cschmidt/lenian/data/attain/model_output/")

mda_f[4]
########### Sollte ich wahrscheinlich händisch machen
mod_wrf <- velox(mda_f[2])
mod_camx <- velox(mda_f[4])

shp_county <- st_read("/gpfs/data/fs71391/cschmidt/lenian/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20200101/")
shp_county <- st_transform(shp_county,4326)

shp_county_fun <- st_as_sf(shp_county)


mod_wrf_mapped  <- mod_wrf$extract(shp_county_fun, fun = function(x) mean(x, na.rm = TRUE),small=TRUE)

mod_camx_mapped  <- mod_camx$extract(shp_county_fun, fun = function(x) mean(x, na.rm = TRUE),small=TRUE)


write.csv(mod_wrf_mapped,"mod_wrf_hist_countymapped.csv",row.names=FALSE)
write.csv(mod_camx_mapped,"mod_camx_hist_countymapped.csv",row.names=FALSE)



#### Map camx files
library(velox)
library(raster)
library(sf)
