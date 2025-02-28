library(terra)

setwd("/gpfs/data/fs71391/cschmidt/lenian/projects/attaino3/repos/attain_paper/code/county_mapping_plots")


shp_in <- vect("/gpfs/data/fs71391/cschmidt/lenian//data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")

meas_meta <- read.csv("../model_comp_final/data/meas/attain_station_meta_bcstations.csv")

coords <- unname(cbind(meas_meta["LAENGE"],meas_meta["BREITE"]))

stat_points <- vect(as.matrix(coords),crs="+proj=longlat +datum=WGS84")


stat_points_lcc <- project(stat_points,shp_in)

plot(stat_points_lcc)

geom(stat_points_lcc)


write.csv(geom(stat_points_lcc),"stat_points_lcc.csv",row.names=FALSE)
