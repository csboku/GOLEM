library(sf)
library(viridis)
library(RColorBrewer)
library(mapsf)

setwd("~/projects/attaino3/repos/attain_paper/code/plot_autstat/")

aut_shp <- st_read("~/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20230101/STATISTIK_AUSTRIA_GEM_20230101.shp")

aut_shp_vienna <- aut_shp[2093:2115,]

aut_shp_districts <- st_read("~/data/shp/OGDEXT_POLBEZ_1_STATISTIK_AUSTRIA_20220101/STATISTIK_AUSTRIA_POLBEZ_20220101.shp")

aut_pop <- read.csv("~/data/stat_aut/gemeinden_2023.csv")

lastind <- 2092

aut_shp$g_name[1:2093]
aut_pop$X[1:2092]

aut_shp$g_name[1000]
aut_pop$X[1000]


aut_shp <- aut_shp[1:2092,]


aut_shape_area <- st_area(aut_shp$geometry) / 1000 / 1000  

aut_pop_density <- aut_pop[1:lastind,24] / aut_shape_area[1:lastind]


plot(aut_pop_density)

my_colors <- brewer.pal(9, "Reds") 
my_colors <- colorRampPalette(my_colors)(30)
my_colors <- my_colors[as.numeric(cut(aut_pop_density_norm,30))]

aut_pop_density_norm <-  as.numeric(aut_pop_density/max(aut_pop_density))

shp_col <- cividis(40)[cut(log(as.numeric(aut_pop_density)),40)]

plot(aut_shp$geometry[1:lastind],col = shp_col)

aut_shp$pop_density <- as.numeric(aut_pop_density[1:lastind])

mf_map(aut_shp,type="choro", var="pop_density",pal=cividis(13))

#### Calc vienna


vienna <- cbind(aut_shp_districts[94,])
vienna$pop_density <- aut_pop[2093,24]/as.numeric(sum(st_area(aut_shp_vienna$geometry)) /1000 / 1000 )
colnames(vienna) <- colnames(aut_shp)
st_geometry(vienna) <- "geometry"
aut_shp <- rbind(aut_shp,vienna)

mf_theme("default")
mf_theme(bg="white")

png("pop_density_gemeinde.png")
mf_map(aut_shp,type="choro", var="pop_density",pal=cividis(13),cex=1.2, leg_title = expression(paste("Population density ", 1/km^2)))
dev.off()

expression(paste(Delta," dmax O"[3]," [", mu, "g/", m^3,"]"))
