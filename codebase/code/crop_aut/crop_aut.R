library(terra)

shp_aut <- vect("~/data/shp/gadm/gadm41_AUT_shp/gadm41_AUT_0.shp")


datadir="~/data/attain/model_output/"
input_files <- list.files(datadir,full.names = T)
input_f <- list.files(datadir,full.names = F)

for (i in c(1:length(input_f))) {
  print(i)
  writeCDF(crop(rast(input_files[i]),shp_aut),paste0(datadir,substr(input_f[i],1,nchar(input_f[1])-3),"_cropped.nc"),"O3",overwrite=T)
}


paste0(datadir,substr(input_f[1],1,nchar(input_f[1])-3),"_cropped.nc")
