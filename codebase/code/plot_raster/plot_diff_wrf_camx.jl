using NCDatasets,CairoMakie,Statistics

cd(@__DIR__)


rmse = function(arr)

end

darken = function(color,n_shade)
    return(RGB(n_shade*color.r, n_shade*color.g, n_shade*color.b))
end

##### Use interpolated data
hist_wrf_cesm_f5 = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/n5_HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_tmean.nc")
hist_camx_cesm_f5 = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/n5_HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_tmean.nc")


mda8_label = "O₃ mda8 [μg/m³]"


hgt_ds = Dataset("/home/cschmidt/data/attain/hgt/hgt_bias_mask_latlon.nc")

hgt_mask = hgt_ds["hgtmask"][:,:]

hgt_mask = rotr90(transpose(hgt_mask))

lon = hist_camx_cesm_f5["lon"][:]
lat = hist_camx_cesm_f5["lat"][:]


hist_wrf_cesm_f5["Band1"][:,:]


hist_diff = mean(hist_wrf_cesm_f5["Band1"][:,:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5["Band1"][:,:],dims=(3))[:,:,1]

heatmap(hist_diff)
heatmap(hgt_mask)


hist_diff_masked = hist_diff .* hgt_mask

replace!(hist_diff_masked,0 => NaN)

fig,ax,hm = heatmap(lon,lat,hist_diff_masked,colormap=cgrad(:bam,20,rev=true,categorical=true),colorrange=(-10,10),nan_color=:lightgrey)
Colorbar(fig[:, end+1], hm,label = "Δ " *mda8_label)

fig

save("att_wrf_camx_hmdiff.png",fig)

#######
####### Same plot for seasonal differences
#######
hist_wrf_cesm_f5 = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/seamean/n5_HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_seasmean.nc")
hist_camx_cesm_f5 = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/seamean/n5_HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_seasmean.nc")

ncvar = "Band4"

hist_wrf_cesm_f5[ncvar]

### JJA 
hist_diff = mean(hist_wrf_cesm_f5[ncvar][:,:,:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5[ncvar][:,:,:],dims=(3))[:,:,1]
hist_diff_masked = hist_diff .* hgt_mask


hist_wrf_cesm_f5[:Band1]  - hist_camx_cesm_f5["Band1"]

hist_diff_djf = mean(hist_wrf_cesm_f5[:Band1][:,:,:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5["Band1"][:,:,:],dims=(3))[:,:,1]
hist_diff_djf_masked = hist_diff_djf .* hgt_mask

hist_diff_mam = mean(hist_wrf_cesm_f5[:Band2][:,:,:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5["Band2"][:,:,:],dims=(3))[:,:,1]
hist_diff_mam_masked = hist_diff_mam .* hgt_mask

hist_diff_jja = mean(hist_wrf_cesm_f5[:Band3][:,:,:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5["Band3"][:,:,:],dims=(3))[:,:,1]
hist_diff_jja_masked = hist_diff_jja .* hgt_mask

hist_diff_son = mean(hist_wrf_cesm_f5[:Band4][:,:,:],dims=(3))[:,:,1]-mean(hist_camx_cesm_f5["Band4"][:,:,:],dims=(3))[:,:,1]
hist_diff_son_masked = hist_diff_son .* hgt_mask

#### New indexing 
hist_diff_djf = hist_wrf_cesm_f5[:Band1]  - hist_camx_cesm_f5["Band1"]
hist_diff_djf_masked = hist_diff_djf .* hgt_mask

hist_diff_mam = hist_wrf_cesm_f5[:Band2]  - hist_camx_cesm_f5["Band2"]
hist_diff_mam_masked = hist_diff_mam .* hgt_mask

hist_diff_jja =  hist_wrf_cesm_f5[:Band3]  - hist_camx_cesm_f5["Band3"]
hist_diff_jja_masked = hist_diff_jja .* hgt_mask

hist_diff_son =  hist_wrf_cesm_f5[:Band4]  - hist_camx_cesm_f5["Band4"]
hist_diff_son_masked = hist_diff_son .* hgt_mask

replace!(hist_diff_djf_masked,0 => NaN)
replace!(hist_diff_mam_masked,0 => NaN)
replace!(hist_diff_jja_masked,0 => NaN)
replace!(hist_diff_son_masked,0 => NaN)





fig,ax,hm = heatmap(lon,lat,hist_diff_djf_masked,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title = "DJF"
ax = Axis(fig[1,2])
heatmap!(lon,lat,hist_diff_mam_masked,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title ="MAM"
ax = Axis(fig[2,1])
heatmap!(lon,lat,hist_diff_jja_masked,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title ="JJA"
ax = Axis(fig[2,2])
heatmap!(lon,lat,hist_diff_son_masked,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title ="SON"
Colorbar(fig[:, end+1], hm,label = "Δ " *mda8_label)

fig

save("wrf_camx_diff_seasonal_masked.png",fig)


fig,ax,hm = heatmap(lon,lat,hist_diff_djf,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title = "DJF"
ax = Axis(fig[1,2])
heatmap!(lon,lat,hist_diff_mam,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title ="MAM"
ax = Axis(fig[2,1])
heatmap!(lon,lat,hist_diff_jja,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title ="JJA"
ax = Axis(fig[2,2])
heatmap!(lon,lat,hist_diff_son,colormap=cgrad(:vik,20,rev=false,categorical=true),colorrange=(-10,10),nan_color=:transparent)
ax.title ="SON"
Colorbar(fig[:, end+1], hm,label = "Δ " *mda8_label)

fig

save("wrf_camx_diff_seasonal.png",fig)


boxplot(skipmissing(hist_wrf_cesm_f5[:Band1][:]))

### Mean absolute differences
wrf = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_tmean.nc")
camx = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_tmean.nc")

wrf_45_nf = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/att_rcp45_2026t35_lonlat_mda8O3_bias_cor_tmean.nc")
wrf_45_ff = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/att_rcp45_2046t55_lonlat_mda8O3_bias_cor_tmean.nc")
wrf_85_nf = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/att_rcp85_2026t35_lonlat_mda8O3_bias_cor_tmean.nc")
wrf_85_ff = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/att_rcp85_2046t55_lonlat_mda8O3_bias_cor_tmean.nc")



wrf


mean(skipmissing(wrf["O3"][:,:] - camx["O3"][:,:]))

mean((skipmissing(wrf["O3"][:,:] - wrf_45_nf["O3"][:,:])))
mean((skipmissing(wrf["O3"][:,:] - wrf_45_ff["O3"][:,:])))
mean((skipmissing(wrf["O3"][:,:] - wrf_85_nf["O3"][:,:])))
mean((skipmissing(wrf["O3"][:,:] - wrf_85_nf["O3"][:,:])))

