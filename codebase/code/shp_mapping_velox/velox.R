library(velox)
library(sf)
library(raster)

args <- commandArgs(trailingOnly = TRUE)

datadir <- args[1]
shapefile <- args[2]
outputdir <- args[3]

input_files <- list.files(datadir,pattern = "*.nc")
input_f <- list.files(datadir,full.names = TRUE,pattern = "*.nc")

shp_in <- st_read(shapefile)
shp_in <- st_transform(shp_in,4326)
shp_geom <- st_as_sf(shp_in)

substr(input_files[1],1,nchar(input_files[1])-3)


for(i in c(1:length(input_f))){
    print("Read")
    raster_in <- velox(input_f[i])
    print("Calulate")
    mapped_out <- raster_in$extract(shp_geom, fun = function(x) mean(x,na.rm=TRUE),small=TRUE)
    mapped_out <- t(mapped_out)
    nacols <- which(colSums(is.na(mapped_out))>=1)
    #print(nacols)
    for(j in nacols){
        mapped_out[,j] <- mean(mapped_out[,j-3:j+3],na.rm = TRUE)
    }
    print("Write")
    write.csv(mapped_out,paste0(outputdir,substr(input_files[i],1,nchar(input_files[i])-3),"_shp_mapped.csv"),row.names=FALSE)
}

print("finished")