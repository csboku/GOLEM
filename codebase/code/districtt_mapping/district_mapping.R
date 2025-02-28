library(terra)

setwd("~/projects/attaino3/repos/attain_paper/code/districtt_mapping")

county_shp <- vect("~/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")
district_shp <- vect("~/data/shp/OGDEXT_POLBEZ_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_POLBEZ_20210101.shp")


county_data <- values(county_shp)
district_data <- values(district_shp)

county_data$id
district_data$id


district_match <- match(substr(county_data$id,1,3),district_data$id)


###### Map counties to districts

datadir <- "~/data/county_mapped/"

input_files <- list.files(datadir,full.names = T)
input_f <- list.files(datadir)

test_in <- read.csv(input_files[1])[,-c(1,2)]

district_int <- unique(district_match)

for (i in district_int) {
  apply(test_in[,which(i == dist_match)], 1, sum,na.rm=T)
}

apply(test_in[,which(3 == dist_match)], 1, sum,na.rm=T)






