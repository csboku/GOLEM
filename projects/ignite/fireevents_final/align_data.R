library(sf)


setwd("~/projects/ignite/fireevents_final")


orig_data <- read.csv("./wildfire_data.csv")
mod_data <- read.csv("./fire_data_v1.0.csv")

colnames(orig_data)

orig_data_sf <- st_as_sf(orig_data, coords = c("WGS84_long","WGS84_lat_"),crs=4326)

orig_data_tansformed  <- st_transform(orig_data_sf, crs = 31287)

mod_data_sf <- st_as_sf(mod_data,sf_column_name = "geometry",crs=31287)
mod_data_sf

sub_idx <- intersect(orig_data_tansformed$geometry,mod_data$geometry)
