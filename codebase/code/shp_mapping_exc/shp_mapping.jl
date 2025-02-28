using Rasters,NCDatasets,Statistics,Plots,StatsPlots,ArchGDAL,Dates,Shapefile

datadir_mda8 = "/home/cschmidt/data/attain/bias_corr_output_mda8/"

inp_mda8_f = readdir(datadir_mda8,join=true)
inp_mda8_files = readdir(datadir_mda8)

##### Shapefiles

shp_district = Shapefile.Table("/home/cschmidt/data/shp/district_aut_lonlat/district_shp_lonlat.shp")
shp_county = Shapefile.Table("/home/cschmidt/data/shp/county_aut_lonlat/county_shp_lonlat.shp")

shp_district.geometry

###### Testign area

mda_rast =  RasterStack(inp_mda8_f[1]) |> replace_missing

mapped_mda8 = Rasters.extract(mda_rast,shp_district.geometry[1])

collect(mdapped_mda8)