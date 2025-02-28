using NCDatasets,Plots,Shapefile


cd(@__DIR__)


datapath = "/home/cschmidt/data/attain/bias_corr_output_exc/timsum/"

inp_f = readdir(datapath,join=true)
inp_f = inp_f[occursin.("d5",inp_f)]
##450x156
##2700x936
exc_hist_wrf_era = Dataset(inp_f[2])
exc_hist_wrf_cesm = Dataset(inp_f[1])
exc_hist_camx_cesm = Dataset(inp_f[3])
exc_rcp45_nf_wrf = Dataset(inp_f[6])
exc_rcp45_ff_wrf = Dataset(inp_f[7])
exc_rcp85_nf_wrf = Dataset(inp_f[8])
exc_rcp85_ff_wrf = Dataset(inp_f[9])

#Get lat and lon
lat = exc_hist_wrf_cesm["lat"][:]
lon = exc_hist_wrf_cesm["lon"][:]

## Labels for Plots
mda8_label = "O₃ mda8 [μg/m³]"
exc_label = "Exceedances"

cs1= cgrad(:batlow, 10, categorical = false)

clim_mag = (1,120)
heatmap(lon,lat,transpose(exc_hist_wrf_era[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("HIST ERA WRF 10Year exc sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("hist_wrf_era_exc_sum")

heatmap(lon,lat,transpose(exc_hist_wrf_cesm[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("HIST CESM WRF 10Year exc sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("hist_wrf_cesm_exc_sum")

heatmap(transpose(exc_hist_camx_cesm[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("HIST CESM CAMx 10Year ecx sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("hist_camx_cesm_exc_sum")

heatmap(transpose(exc_rcp45_nf_wrf[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("NF RCP45 WRF 10Year exc sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("nf45_wrf_cesm_exc_sum")

heatmap(transpose(exc_rcp45_ff_wrf[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("FF RCP45 WRF 10Year exc sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("ff45_wrf_cesm_exc_sum")

heatmap(transpose(exc_rcp85_nf_wrf[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("NF RCP85 WRF 10Year exc sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("nf85_wrf_cesm_exc_sum")

heatmap(transpose(exc_rcp85_ff_wrf[:Band1])/10,c=cs1,clim=clim_mag,colorbar_title=mda8_label,framestyle=:box)
title!("FF RCP85 WRF 10Year exc sum")
xlabel!("Longitude [°]")
ylabel!("Latitude [°]")
png("ff85_wrf_cesm_exc_sum")

####### Write Plot function for all the stuff 
map_heat_att = function (ds,cs,clim_p,ctitle,fstyle,ptitle)
    p = heatmap(lon,lat,transpose(ds),c=cs,clim=clim_p,colorbar_title=ctitle,framestyle=fstyle)
    title!(ptitle)
    xlabel!("Longitude [°]")
    ylabel!("Latitude [°]")
    #close(ds)
    return(p)
end

map_heat_att(exc_hist_wrf_cesm[:Band1]/10,cs1,clim_mag,exc_label,:box,"HIST CESM 10YEAR exc")

###### Write function which reads in file
map_heat_att = function (filen,nckey,cs,clim_p,ctitle,fstyle,ptitle)
    ds=Dataset(filen)
    p = heatmap(lon,lat,transpose(ds[nckey]),c=cs,clim=clim_p,colorbar_title=ctitle,framestyle=fstyle)
    title!(ptitle)
    xlabel!("Longitude [°]")
    ylabel!("Latitude [°]")
    return(p)
end

map_heat_att(inp_f[2],:Band1,cs1,clim_mag,exc_label,:box,"HIST CESM 10YEAR exc")

####### Difference maps
cs2 = cgrad(:vik,30,rev=false,categorical=false)

heatmap(transpose(exc_rcp45_nf_wrf[:Band1]/10 - exc_hist_wrf_era[:Band1]/10),c=cs2,clim=(-30,30))
title!("Diff exceedances RCP45 NF vs. HIST")
png("d5_hist_rcp45nf_excdiff")

heatmap(transpose(exc_rcp45_ff_wrf[:Band1]/10 - exc_hist_wrf_era[:Band1]/10),c=cs2,clim=(-30,30))
title!("Diff exceedances RCP45 FF vs. HIST")
png("d5_hist_rcp45ff_excdiff")

heatmap(transpose(exc_rcp85_nf_wrf[:Band1]/10 - exc_hist_wrf_era[:Band1]/10),c=cs2,clim=(-30,30))
title!("Diff exceedances RCP85 NF vs. HIST")
png("d5_hist_rcp85nf_excdiff")

heatmap(transpose(exc_rcp85_ff_wrf[:Band1]/10 - exc_hist_wrf_era[:Band1]/10),c=cs2,clim=(-30,30))
title!("Diff exceedances RCP85 FF vs. HIST")
png("d5_hist_rcp85ff_excdiff")

########
######## Plots with fuction
########

inputdir = "/home/cschmidt/data/attain/bias_corr_output_exc/timsum/"
inp_f = readdir(inputdir,join=true)
inp_files = readdir(inputdir,join=false)
inp_f = inp_f[occursin.("divd5",inp_f)]
inp_files = inp_files[occursin.("divd5",inp_files)]

println.(inp_files)

model_str = ["Hist WRF CESM","Hist WRF ERA5","Hist CAMx CESM","Hist CAMx ER5A","Hist WRF RCP26","NearFuture WRF RCP45","FarFuture WRF RCP85","NearFuture WRF RCP85","FarFuture WRF RCP85","FarFuture WRF RCP26","NearFuture WRF RCP26"]

model_str_f = ["hist_wrf_cesm","hist_wrf_era","hist_camx_cesm","hist_camx_era","hist_wrf_rcp26","nearfuture_wrf_rcp45","farfuture_wrf_rcp45","nearfuture_wrf_rcp85","farfuture_wrf_rcp85","farfuture_wrf_rcp26","nearfuture_wrf_rcp26"]

map_heat_att(inp_f[2],:Band1,cs1,clim_mag,exc_label,:box,model_str[2]*" 10 year exc mean")

map_heat_att(inp_f[1],:Band1,cs1,clim_mag,exc_label,:box,model_str[1]*" 10 year exc mean")

for i in eachindex(inp_f)
    p = map_heat_att(inp_f[i],:Band1,cs1,clim_mag,exc_label,:box,model_str[i]*" 10 year exc mean")
    png(model_str_f[i]*"_10ymean_exc_mean")    
end


##### Difference heatmaps
