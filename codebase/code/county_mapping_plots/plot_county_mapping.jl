using DelimitedFiles,Statistics,Plots,Shapefile,Plots.PlotMeasures

cd(@__DIR__)

datadir_mda8 = "/home/cschmidt/data/attain/shp_mapped_spatial/county_mapped/mda8/"

mda8_files = readdir(datadir_mda8,join=false)
mda8_f = readdir(datadir_mda8,join=true)

##### Read in shape data
aut_shp = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")

aut_geoms = aut_shp.geometry


#### Compare wrfchem hist vs. camx hist

mda8_files[9]

wrf_hist = readdlm(mda8_f[1],',',skipstart=1)[:,3:end]
camx_hist = readdlm(mda8_f[3],',',skipstart=1)[:,3:end]

wrf_45_nf = readdlm(mda8_f[6],',',skipstart=1)[:,3:end]
wrf_45_ff = readdlm(mda8_f[7],',',skipstart=1)[:,3:end]

wrf_85_nf = readdlm(mda8_f[8],',',skipstart=1)[:,3:end]
wrf_85_ff = readdlm(mda8_f[9],',',skipstart=1)[:,3:end]



###### Plot difference between models
plot(aut_geoms,fill=cgrad(:roma),fill_z=mean(wrf_hist,dims=1)-mean(camx_hist,dims=1),clim=(-10,10),grid=false,axis=false,colorbar_title="Δ O₃ mda8 [μg/m³]",size=(800,500),left_margin=-18mm)
title!("WRF HIST vs. CAMx HIST")
png("plots/comp_hist_wrf_camx")


###### Plot differences in tseries_scenarios
plot(aut_geoms,fill=cgrad(:roma),fill_z=mean(wrf_hist,dims=1)-mean(wrf_45_nf,dims=1),clim=(-10,10),grid=false,axis=false,colorbar_title="Δ O₃ mda8 [μg/m³]",size=(800,500),left_margin=-18mm)
title!("WRF HIST vs. WRF RCP45 NF")
png("plots/wrfdiff_45_nf")


plot(aut_geoms,fill=cgrad(:roma),fill_z=mean(wrf_hist,dims=1)-mean(wrf_45_ff,dims=1),clim=(-10,10),grid=false,axis=false,colorbar_title="Δ O₃ mda8 [μg/m³]",size=(800,500),left_margin=-18mm)
title!("WRF HIST vs. WRF RCP45 FF")
png("plots/wrfdiff_45_ff")


plot(aut_geoms,fill=cgrad(:roma),fill_z=mean(wrf_hist,dims=1)-mean(wrf_85_nf,dims=1),clim=(-10,10),grid=false,axis=false,colorbar_title="Δ O₃ mda8 [μg/m³]",size=(800,500),left_margin=-18mm)
title!("WRF HIST vs. WRF RCP85 NF")
png("plots/wrfdiff_85_nf")


plot(aut_geoms,fill=cgrad(:roma),fill_z=mean(wrf_hist,dims=1)-mean(wrf_85_ff,dims=1),clim=(-10,10),grid=false,axis=false,colorbar_title="Δ O₃ mda8 [μg/m³]",size=(800,500),left_margin=-18mm)
title!("WRF HIST vs. WRF RCP85 FF")
png("plots/wrfdiff_85_ff")


