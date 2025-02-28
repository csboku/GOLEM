library(terra)

aut_hgt <- rast("/home/cschmidt/data/attain/hgt/att_hgt_bias_latlon.nc")

aut_hgt

#plot(aut_hgt)

aut_hgt[aut_hgt < 1500] <- 1
aut_hgt[aut_hgt >= 1500] <- 0

terra::writeCDF(aut_hgt,"~/data/attain/hgt/hgt_bias_mask_latlon.nc","hgtmask")
