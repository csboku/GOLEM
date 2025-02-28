library(terra)


ncin <- rast("~/data/attain/hgt/att_hgt_latlon.nc")

shp_in <- vect("~/data/shp/NUTS_BN_03M_2021_4326.shp/NUTS_BN_03M_2021_4326.shp")


ncin

nc_coords <- crds(ncin)

nc_coords[1,]

plot(ncin)
lines(shp_in[which(shp_in$LEVL_CODE == 0)])
lines(nc_coords[,1],nc_coords[,2],lw=0.5)
lines(nc_coords[,2],nc_coords[,1])
lines(nc_coords,lw=0.2)
