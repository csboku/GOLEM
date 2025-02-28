using Rasters,ArchGDAL,NCDatasets,CairoMakie,CSV,DataFrames

cd(@__DIR__)

wrf_bias_hist = Raster("/gpfs/data/fs71391/cschmidt/lenian/data/attain/bias_corr_output_mda8/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")

meas_meta = CSV.read("aut_sites_meta_utf.csv",DataFrame)

shp_aut = ArchGDAL.getlayer(shp_aut,0)

shp_aut

ArchGDAL.getgeom.(shp_aut)



lines(shp_aut)