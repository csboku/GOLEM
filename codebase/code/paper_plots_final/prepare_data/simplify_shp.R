library(terra)

Sys.setenv(PROJ_LIB="/home/cschmidt/micromamba/envs/cs-r/share/proj")

rm()


shp_in <- vect("/sto2/data/lenian/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")

shp_simple <- simplifyGeom(shp_in,tolerance=100,preserveTopology=TRUE,makeValid=TRUE)

writeVector(shp_simple,"/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/paper_plots_final/data/shp/aut_gemeinde_simplified_4326.shp")



###############################
library(sf)


Sys.setenv(PROJ_LIB="/home/cschmidt/micromamba/envs/cs-r/share/proj")

rm()


shp_in <- st_read("/sto2/data/lenian/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")

shp_simple <- st_simplify(shp_in,dTolerance=1000)

st_write(shp_simple,"/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/paper_plots_final/data/shp/aut_gemeinde_simplified_4326.shp")
