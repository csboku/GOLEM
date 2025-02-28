using Plots,Shapefile,CSV,DataFrames,GeoDataFrames,ArchGDAL

shp_in = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20230101/STATISTIK_AUSTRIA_GEM_20230101_rep.shp")

pop_data = CSV.read("/home/cschmidt/data/stat_aut/gemeinden_2023.csv",DataFrame)

pop_data = pop_data[1:end-1,:]

shp_in.geometry

pop_data


geoms_shp = GeoDataFrames.read("/home/cschmidt/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20230101/STATISTIK_AUSTRIA_GEM_20230101.shp")

geoms = geoms_shp[:,1]
geom_area = ArchGDAL.geomarea.(geoms_shp[:,1]) / 1000 / 1000

pop_density = pop_data[:,24][1:end-1] ./ geom_area[1:2092]

geoms[1:2092]

plot(shp_in.geometry[1:2092],fill_z=pop_density,clim=(0,5000),fill=palette(:cividis))