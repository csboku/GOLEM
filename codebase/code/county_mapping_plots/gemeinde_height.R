library(terra)

setwd("/home/cschmidt/projects/attaino3/repos/attain_paper/code/county_mapping_plots")

shp_in <- vect("/home/cschmidt/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")

shp_in

hgt <- rast("/home/cschmidt/data/attain/hgt/att_hgt_latlon.nc")

crs(shp_in)


shp_in <- project(shp_in,hgt)


county_height <- terra::extract(hgt,shp_in,fun=mean)


write.csv(county_height,file="shp_height.csv",row.names=FALSE)

hist(county_height$HGT_XTIME)
