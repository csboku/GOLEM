using CairoMakie,NCDatasets

##### Plot exceedances diff in panels
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


map_heat_att_diff = function (filen,filen2,nckey,cs,clim_p)
    ds=Dataset(filen)
    ds2=Dataset(filen2)
    p = heatmap!(lon,lat,ds[nckey]/10-ds2[nckey]/10,colormap=cs,colorrange=clim_p)
    close(ds)
    close(ds2)
    return(p)
end

### Plot panel of diff

model_str = ["Hist WRF CESM","Hist WRF ERA5","Hist CAMx CESM","Hist CAMx ER5A","Hist WRF RCP26","NearFuture WRF RCP45","FarFuture WRF RCP85","NearFuture WRF RCP85","FarFuture WRF RCP85","FarFuture WRF RCP26","NearFuture WRF RCP26"]

model_str_f = ["hist_wrf_cesm","hist_wrf_era","hist_camx_cesm","hist_camx_era","hist_wrf_rcp26","nearfuture_wrf_rcp45","farfuture_wrf_rcp45","nearfuture_wrf_rcp85","farfuture_wrf_rcp85","farfuture_wrf_rcp26","nearfuture_wrf_rcp26"]

cs1= cgrad(:bam, 20, categorical = false,rev=true)
o3_levs = range(-30, 30, length = 21)
clim_mag = (-30,30)

cont_o3 = Figure(resolution=(1200,800))
ax_o3 = Axis(cont_o3[1,1])
oax = map_heat_att_diff(inp_f[6],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP4.5 NF - HIST "
ax_o3 = Axis(cont_o3[1,2])
map_heat_att_diff(inp_f[7],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP4.5 FF - HIST"
ax_o3 = Axis(cont_o3[2,1])
oax = map_heat_att_diff(inp_f[8],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 NF - HIST "
ax_o3 = Axis(cont_o3[2,2])
oax = map_heat_att_diff(inp_f[9],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 FF - HIST "
Colorbar(cont_o3[:, 3],oax,label="Δ Exceedances",ticks = collect(o3_levs))
save("heat_timsum_o3_pan_exc.png",cont_o3)

cont_o3
Colorbar(cont_o3[:, 4],oax,label="MDA8 O₃ [μg/m³]",ticks = collect(o3_levs))





#### mda8 difference
datapath = "/home/cschmidt/data/attain/bias_corr_output_mda8/timmean/"

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




map_heat_att = function (filen,nckey,cs,clim_p,ctitle,fstyle,ptitle)
    ds=Dataset(filen)
    p = heatmap(lon,lat,transpose(ds[nckey]),colormap=cs,colorrange=clim_p)
    title!(ptitle)
    xlabel!("Longitude [°]")
    ylabel!("Latitude [°]")
    return(p)
end

map_heat_att_diff = function (filen,filen2,nckey,cs,clim_p)
    ds=Dataset(filen)
    ds2=Dataset(filen2)
    p = heatmap!(lon,lat,ds[nckey]-ds2[nckey],colormap=cs,colorrange=clim_p)
    close(ds)
    close(ds2)
    return(p)
end

### Plot panel of diff
model_str = ["Hist WRF CESM","Hist WRF ERA5","Hist CAMx CESM","Hist CAMx ER5A","Hist WRF RCP26","NearFuture WRF RCP45","FarFuture WRF RCP85","NearFuture WRF RCP85","FarFuture WRF RCP85","FarFuture WRF RCP26","NearFuture WRF RCP26"]

model_str_f = ["hist_wrf_cesm","hist_wrf_era","hist_camx_cesm","hist_camx_era","hist_wrf_rcp26","nearfuture_wrf_rcp45","farfuture_wrf_rcp45","nearfuture_wrf_rcp85","farfuture_wrf_rcp85","farfuture_wrf_rcp26","nearfuture_wrf_rcp26"]

model_str[1]
model_str[6]

map_heat_att_diff(inp_f[6],inp_f[1],:Band1,cs1,clim_mag)
map_heat_att_diff(inp_f[7],inp_f[1],:Band1,cs1,clim_mag)
map_heat_att_diff(inp_f[8],inp_f[1],:Band1,cs1,clim_mag)
map_heat_att_diff(inp_f[9],inp_f[1],:Band1,cs1,clim_mag)

cs1= cgrad(:bam, 20, categorical = false,rev=true)
o3_levs = range(-20, 20, length = 21)
clim_mag = (-20,20)

cont_o3 = Figure(resolution=(1200,800))
ax_o3 = Axis(cont_o3[1,1])
oax = map_heat_att_diff(inp_f[6],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP4.5 NF - HIST "
ax_o3 = Axis(cont_o3[1,2])
map_heat_att_diff(inp_f[7],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP4.5 FF - HIST"
ax_o3 = Axis(cont_o3[2,1])
oax = map_heat_att_diff(inp_f[8],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 NF - HIST "
ax_o3 = Axis(cont_o3[2,2])
oax = map_heat_att_diff(inp_f[9],inp_f[1],:Band1,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 FF - HIST "
Colorbar(cont_o3[:, 3],oax,label="MDA8 O₃ [μg/m³]",ticks = collect(o3_levs))
save("heat_timsum_o3_mda8.png",cont_o3)

cont_o3


##### Seasonal exceedance Plots

datapath = "/home/cschmidt/data/attain/bias_corr_output_exc/seasum/"

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


map_heat_att_diff = function (filen,filen2,nckey,cs,clim_p)
    ds=Dataset(filen)
    ds2=Dataset(filen2)
    p = heatmap!(lon,lat,ds[nckey]/10-ds2[nckey]/10,colormap=cs,colorrange=clim_p)
    close(ds)
    close(ds2)
    return(p)
end

### Plot panel of diff

model_str = ["Hist WRF CESM","Hist WRF ERA5","Hist CAMx CESM","Hist CAMx ER5A","Hist WRF RCP26","NearFuture WRF RCP45","FarFuture WRF RCP85","NearFuture WRF RCP85","FarFuture WRF RCP85","FarFuture WRF RCP26","NearFuture WRF RCP26"]

model_str_f = ["hist_wrf_cesm","hist_wrf_era","hist_camx_cesm","hist_camx_era","hist_wrf_rcp26","nearfuture_wrf_rcp45","farfuture_wrf_rcp45","nearfuture_wrf_rcp85","farfuture_wrf_rcp85","farfuture_wrf_rcp26","nearfuture_wrf_rcp26"]

cs1= cgrad(:bam, 20, categorical = false,rev=true)
o3_levs = range(-30, 30, length = 21)
clim_mag = (-30,30)

cont_o3 = Figure(resolution=(1200,800))
ax_o3 = Axis(cont_o3[1,1])
oax = map_heat_att_diff(inp_f[6],inp_f[1],:Band4,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP4.5 NF - HIST "
ax_o3 = Axis(cont_o3[1,2])
map_heat_att_diff(inp_f[7],inp_f[1],:Band3,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP4.5 FF - HIST"
ax_o3 = Axis(cont_o3[2,1])
oax = map_heat_att_diff(inp_f[8],inp_f[1],:Band3,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 NF - HIST "
ax_o3 = Axis(cont_o3[2,2])
oax = map_heat_att_diff(inp_f[9],inp_f[1],:Band3,cs1,clim_mag)
ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 FF - HIST "
Colorbar(cont_o3[:, 3],oax,label="Δ Exceedances",ticks = collect(o3_levs))
save("heat_timsum_o3_pan_jja.png",cont_o3)

cont_o3

att_in = Dataset(inp_f[1])

