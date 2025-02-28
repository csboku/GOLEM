using NCDatasets,Plots,Statistics,Shapefile

wrf = Dataset("/home/cschmidt/data/attain/model_output/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_cropped.nc")
camx = Dataset("/home/cschmidt/data/attain/model_output/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda_cropped.nc")

shp_aut = Shapefile.Table("/home/cschmidt/data/shp/gadm/gadm41_AUT_shp/gadm41_AUT_0.shp")

mean(wrf["O3"][:,:,:],dims=3)[:,:,1] |> heatmap
mean(camx["O3"][:,:,:],dims=3)[:,:,1] |> heatmap

wrf |> keys

wrf["latitude"][:]
wrf["longitude"][:]

heatmap(wrf["longitude"][:],reverse(wrf["latitude"][:]),rotl90(mean(wrf["O3"][:,:,:],dims=3)[:,:,1] - mean(camx["O3"][:,:,:],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-10,10),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
plot!(shp_aut.geometry,fill=:transparent)
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx")
png("/home/cschmidt/projects/attaino3/plots/maps/raw_model/wrf_camx_ally")

findall(jja_cesm_sub .==1)


heatmap(wrf["longitude"][:],reverse(wrf["latitude"][:]),rotl90(mean(wrf["O3"][:,:,findall(jja_cesm_sub .==1)],dims=3)[:,:,1] - mean(camx["O3"][:,:,findall(jja_cesm_sub .==1)],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-10,10),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
plot!(shp_aut.geometry,fill=:transparent)
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx JJA")
png("/home/cschmidt/projects/attaino3/plots/maps/raw_model/wrf_camx_jja")

heatmap(wrf["longitude"][:],reverse(wrf["latitude"][:]),rotl90(mean(wrf["O3"][:,:,findall(mam_cesm_sub .==1)],dims=3)[:,:,1] - mean(camx["O3"][:,:,findall(mam_cesm_sub .==1)],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-10,10),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
plot!(shp_aut.geometry,fill=:transparent)
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx MAM")
png("/home/cschmidt/projects/attaino3/plots/maps/raw_model/wrf_camx_mam")


heatmap(wrf["longitude"][:],reverse(wrf["latitude"][:]),rotl90(mean(wrf["O3"][:,:,findall(son_cesm_sub .==1)],dims=3)[:,:,1] - mean(camx["O3"][:,:,findall(son_cesm_sub .==1)],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-10,10),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
plot!(shp_aut.geometry,fill=:transparent)
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx SON")
png("/home/cschmidt/projects/attaino3/plots/maps/raw_model/wrf_camx_son")

heatmap(wrf["longitude"][:],reverse(wrf["latitude"][:]),rotl90(mean(wrf["O3"][:,:,findall(djf_cesm_sub .==1)],dims=3)[:,:,1] - mean(camx["O3"][:,:,findall(djf_cesm_sub .==1)],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-20,20),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
plot!(shp_aut.geometry,fill=:transparent)
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx DJF")
png("/home/cschmidt/projects/attaino3/plots/maps/raw_model/wrf_camx_djf")



wrf_bias = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
camx_bias = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")

wrf_bias["O3"]
camx_bias["O3"]

heatmap(transpose(mean(wrf_bias["O3"][:,:,:],dims=3)[:,:,1] - mean(camx_bias["O3"][:,:,:],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-10,10),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx (bias corrected)")


heatmap(transpose(mean(wrf_bias["O3"][:,:,:],dims=3)[:,:,1]) - rotl90(mean(wrf["O3"][:,:,:],dims=3)[:,:,1]),c=cgrad(:roma,rev=true),clim=(-10,10),framestyle=:box,colorbar_title="Δ MDA8 O₃ [μgm⁻³]")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
title!("WRFChem - CAMx (bias corrected)")

transpose(mean(wrf_bias["O3"][1:end-1,:,:],dims=3)[:,:,1]) 
rotl90(mean(wrf["O3"][:,:,:],dims=3)[:,:,1])

