library(terra)
library(RColorBrewer)

set_Polypath(FALSE)

setwd("~/projects/attaino3/repos/attain_paper/code/shp_mapping_terra/")

datadir <- "/home/cschmidt/data/attain/shp_mapped/district_mapped/mda8"

shp_district <- vect("~/data/shp/district_aut_lonlat/district_shp_lonlat.shp")

shp_district

inp_f <- list.files(datadir,full.names = T)
inp_files <- list.files(datadir,full.names = F)

csv_in <- read.csv(inp_f[1])

csv_in$date <- as.Date(csv_in$date)

year <- format(csv_in$date, format="%Y")

res <- aggregate(csv_in[,-c(1,2)],by = list(year), FUN = sum)

val <- as.numeric(res[1,-1])

colPal <- colorRampPalette(brewer.pal(10,"Spectral"))
mcol <- colPal(10)[as.numeric(cut(val,breaks = 10))]

png("test.png")
plot(shp_district,col=mcol)
dev.off()


