using NCDatasets,Statistics,Plots,DataFrames,CSV,ProgressMeter,CFTime,Rasters,EmpiricalOrthogonalFunctions

cd(@__DIR__)

datapath_mda = "/home/cschmidt/data/attain/bias_corr_output_mda8/" 
datapath_exc = "/home/cschmidt/data/attain/bias_corr_output_exc/"


mda_files = readdir(datapath_mda)
mda_f = readdir(datapath_mda,join=true)

exc_files = readdir(datapath_exc)
exc_f = readdir(datapath_exc,join=true)

mda8_label = "O₃ mda8 [μg/m³]"
exc_label = "Exceedances"
##### Plot the difference between CESM and ERA5
# O3 data ca. 60 MB

mda_files[6:9]
ncin = Dataset(mda_f[1])

hist_wrf_era = Dataset(mda_f[2])
hist_wrf_cesm = Dataset(mda_f[1])
hist_camx_cesm = Dataset(mda_f[3])
rcp45_nf_wrf = Dataset(mda_f[6])
rcp45_ff_wrf = Dataset(mda_f[7])
rcp85_nf_wrf = Dataset(mda_f[8])
rcp85_ff_wrf = Dataset(mda_f[9])

exc_hist_wrf_era = Dataset(exc_f[2])
exc_hist_wrf_cesm = Dataset(exc_f[1])
exc_hist_camx_cesm = Dataset(exc_f[3])
exc_rcp45_nf_wrf = Dataset(exc_f[6])
exc_rcp45_ff_wrf = Dataset(exc_f[7])
exc_rcp85_nf_wrf = Dataset(exc_f[8])
exc_rcp85_ff_wrf = Dataset(exc_f[9])

#### Heatmap 10 year difference

cgrad(:lajolla25)
cgrad(:lajolla)

cs1= cgrad(:lajolla, 10, categorical = true)
cs1= cgrad(:bam, 10, categorical = true)

heatmap(transpose(mean(hist_wrf_cesm["O3"][:],dims=3)[:,:,1]),c=cs1,clim=(40,120),colorbar_title=mda8_label)
title!("HIST CESM WRF 10Year mean")
png("hist_wrf_cesm_mda8_mean")


heatmap(transpose(mean(hist_camx_cesm["O3"][:],dims=3)[:,:,1]),c=cs1,clim=(40,120),colorbar_title=mda8_label)
title!("HIST CESM CAMX 10Year mean")
png("hist_camx_cesm_mda8_mean")


title!("NF RCP45 WRF 10Year mean")
png("nf45_wrf_cesm_mda8_mean")

heatmap(transpose(mean(rcp45_ff_wrf["O3"][:],dims=3)[:,:,1]),c=cs1,clim=(40,120),colorbar_title=mda8_label)
title!("FF RCP45 WRF 10Year mean")
png("ff45_wrf_cesm_mda8_mean")

heatmap(transpose(mean(rcp85_nf_wrf["O3"][:],dims=3)[:,:,1]),c=cs1,clim=
(40,120),colorbar_title=mda8_label)
title!("NF RCP85 WRF 10Year mean")
png("nf85_wrf_cesm_mda8_mean")

heatmap(transpose(mean(rcp85_ff_wrf["O3"][:],dims=3)[:,:,1]),c=cs1,clim=(40,120),colorbar_title=mda8_label)
title!("FF RCP85 WRF 10Year mean")
png("ff85_wrf_cesm_mda8_mean")

#### Heatmap 10 yearly exc

heatmap(transpose(sum(exc_hist_wrf_cesm["O3"][:]/10,dims=3)[:,:,1]),c=cs1,clim=(0,120),colorbar_title=exc_label)
title!("HIST CESM WRF 10Year exc sum")
png("hist_wrf_cesm_exc_sum")


heatmap(transpose(sum(exc_hist_camx_cesm["O3"][:]/10,dims=3)[:,:,1]),c=cs1,clim=(0,120),colorbar_title=exc_label)
title!("HIST CESM CAMX 10Year exc sum")
png("hist_camx_cesm_exc_sum")


heatmap(transpose(sum(exc_rcp45_nf_wrf["O3"][:]/10,dims=3)[:,:,1]),c=cs1,clim=(0,120),colorbar_title=exc_label)
title!("NF RCP45 WRF 10Year exc sum")
png("nf45_wrf_cesm_exc_sum")

heatmap(transpose(sum(exc_rcp45_ff_wrf["O3"][:]/10,dims=3)[:,:,1]),c=cs1,clim=(0,120),colorbar_title=exc_label)
title!("FF RCP45 WRF 10Year exc sum")
png("ff45_wrf_cesm_mda8_exc_sum")

heatmap(transpose(sum(exc_rcp85_nf_wrf["O3"][:]/10,dims=3)[:,:,1]),c=cs1,clim=(0,120),colorbar_title=exc_label)
title!("NF RCP85 WRF 10Year exc sum")
png("nf85_wrf_cesm_mda8_exc_sum")

heatmap(transpose(sum(exc_rcp85_ff_wrf["O3"][:]/10,dims=3)[:,:,1]),c=cs1,clim=(0,120),colorbar_title=exc_label)
title!("FF RCP85 WRF 10Year exc sum")
png("ff85_wrf_cesm_mda8_exc_sum")




###### Difference Plots
cs2 = cgrad(:bam, 10, categorical = true,rev=true)

tmean_o3 = function (ds)
    return(transpose(mean(ds["O3"][:],dims=3)[:,:,1])) 
end
tsum_o3 = function (ds)
    return(transpose(sum(ds["O3"][:]/10,dims=3)[:,:,1])) 
end


heatmap(tsum_o3(exc_rcp45_nf_wrf)-tsum_o3(exc_hist_wrf_cesm),clim=(-30,30),c =cs2,colorbar_title="Δ Exceedances")
title!("Diff exceedances RCP45 NF vs. HIST")
png("hist_rcp45nf_excdiff")

heatmap(tsum_o3(exc_rcp45_ff_wrf)-tsum_o3(exc_hist_wrf_cesm),clim=(-30,30),c =cs2,colorbar_title="Δ Exceedances")
title!("Diff exceedances RCP45 FF vs. HIST")
png("hist_rcp45ff_excdiff")

heatmap(tsum_o3(exc_rcp85_nf_wrf)-tsum_o3(exc_hist_wrf_cesm),clim=(-30,30),c =cs2,colorbar_title="Δ Exceedances")
title!("Diff exceedances RCP85 NF vs. HIST")
png("hist_rcp85nf_excdiff")

heatmap(tsum_o3(exc_rcp85_ff_wrf)-tsum_o3(exc_hist_wrf_cesm),clim=(-30,30),c =cs2,colorbar_title="Δ Exceedances")
title!("Diff exceedances RCP85 FF vs. HIST")
png("hist_rcp85ff_excdiff")

## Plot difference between camx and wrfchem after bias correction 
hist_camx_cesm
hist_wrf_cesm

lon = hist_camx_cesm["lon"][:]
lat = hist_camx_cesm["lat"][:]

hist_diff = transpose(mean(hist_wrf_cesm["O3"][:],dims=(3))[:,:,1])-transpose(mean(hist_camx_cesm["O3"][:],dims=(3))[:,:,1])

cgrad(:roma,10,rev=true,categorical=true)

heatmap(lon,lat,hist_diff,clim=(-15,15),c=cgrad(:bam,20,rev=true,categorical=true))

##### Use interpolated data
hist_wrf_cesm_f5 = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/d5_HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_tmean.nc")
hist_camx_cesm_f5 = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/d5_HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_tmean.nc")

hgt_ds = Dataset("/home/cschmidt/data/attain/hgt/hgt_bias_mask_latlon.nc")

hgt_mask = hgt_ds["hgtmask"][:]

hgt_mask = rotl90(hgt_mask)

lon = hist_camx_cesm_f5["lon"][:]
lat = hist_camx_cesm_f5["lat"][:]

hist_diff = transpose(mean(hist_wrf_cesm_f5["Band1"][:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5["Band1"][:],dims=(3))[:,:,1])

hist_diff_masked = hist_diff .* hgt_mask

heatmap(lon,lat,hist_diff_masked,clim=(-10,10),c=cgrad(:bam,10,rev=true,categorical=true),colorbar_title="Δ " *mda8_label)
png("diff_wrf_camx_timmean.png")


heatmap(hgt_mask)
heatmap(hist_diff)
