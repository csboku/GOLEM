using Plots,StatsPlots,NCDatasets,Statistics,CFTime,ProgressMeter,CSV,DataFrames,Dates,JLD,Missings,DelimitedFiles

cd(@__DIR__)

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end

linec1 = RGB(68/255,119/255,170/255)
linec2 = RGB(102/255,204/255,238/255)
linec3 = RGB(34/255,136/255,51/255)
linec4 = RGB(204/255,187/255,68/255)
linec5 = RGB(238/255,102/255,119/255)
linec6 = RGB(170/255,51/255,119/255)
linec7 = RGB(187/255,187/255,187/255)

bcols = ["#0A7373", "#EDAA25", "#C43302"]

bcols = cgrad(bcols,categorical=true)

stat_meta = CSV.read("aut_sites_meta_utf.csv",DataFrame)

statcodes = load("statcodes.jld")
statcodes
statcodes["codes"]


stat_meta[!,"station_european_code"]

season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]
season_son = ["September","October","November"]
season_djf = ["December","January","February"]


s_jja = function(d)
    return(findall(in(season_jja).(monthname.(d))))
end

s_mam = function(d)
    return(findall(in(season_mam).(monthname.(d))))
end

agg_seas_df = function(df)
    return(mean.(skipmissing.(eachcol(df))))
end

agg_seas_df_sum = function(df)
    return(sum.(skipmissing.(eachcol(df))))
end


na_rm = function (df)
    return(collect(skipmissing(df)))
end

calc_exc_mda8 = function(df)
    return(ifelse.(df .< 120,0,1))
end

getvec = function(df)
    return(vec(Matrix(df)))
end


#gdf = groupby(bias_camx_exc_df,:year)
#valuecols(gdf)
#bias_camx_exc_yagg

yearly_agg = function (df,fun)
    gdf = groupby(df,:year;skipmissing=true)
    return(combine(gdf, names(gdf,Not([:date,:year])) .=> [fun]))
end



replacemissing = function (df,val)
    for c ∈ eachcol(df)
        replace!(c, missing => val)
    end
    return(df)
end    



#### Types in meas aut exc are not good
#testdf = Missings.replace.(meas_aut_exc,0)

#for c ∈ eachcol(meas_aut_exc)
#    replace!(c, missing => 0)
#end

#meas_aut_exc



###### Create dates for CESM
#cesm_date_range = DateTimeNoLeap(2007,1,1,) : Day(1) : DateTimeNoLeap(2016,12,31)
#cesm_dates = collect(cesm_date_range)
#cesm_dates = Dates_noleap(cesm_date)

###### Load dates from source file 
#meas_raw = CSV.read("/home/cschmidt/data/measmod_csv/vault/meas_aut_o3_mda8_nafix.csv",DataFrame)
#meas_dates = meas_raw[:,:date]
#@save "meas_dates.jld" meas_dates cesm_dates


##Load date jld

att_dates = load("meas_dates.jld")
att_dates_cesm = att_dates["cesm_dates"]
att_dates_meas = att_dates["meas_dates"]

####### Subset indices per season_djf

mam_s_cesm = findall(Month.(att_dates_cesm) == season_mam)

mam_cesm_sub = in(season_mam).(monthname.(att_dates_cesm))
jja_cesm_sub = in(season_jja).(monthname.(att_dates_cesm))
son_cesm_sub = in(season_son).(monthname.(att_dates_cesm)) 
djf_cesm_sub = in(season_djf).(monthname.(att_dates_cesm))

mam_meas_sub = in(season_mam).(monthname.(att_dates_meas))
jja_meas_sub = in(season_jja).(monthname.(att_dates_meas))
son_meas_sub = in(season_son).(monthname.(att_dates_meas)) 
djf_meas_sub = in(season_djf).(monthname.(att_dates_meas))




######## Look at future data

future_datapath = "/home/cschmidt/data/attain/attain_future_csv/mda8"
future_datapath_exc = "/home/cschmidt/data/attain/attain_future_csv/exc"


futdat_files = readdir(future_datapath)
futdat_f = readdir(future_datapath,join=true)

futdat_files_exc = readdir(future_datapath_exc)
futdat_f_exc = readdir(future_datapath_exc,join=true)

fut_hist = readdlm(futdat_f[1],',')

#testdata = readdlm(futdat_f[1],',')
#codes = testdata[1,:] 
#@save "statcodes.jld" codes

fut_hist =  readdlm(futdat_f[1], ',',skipstart=1)
fut_ff_rcp45 = readdlm(futdat_f[2], ',',skipstart=1)
fut_nf_rcp45 = readdlm(futdat_f[3], ',',skipstart=1)
fut_ff_rcp85 = readdlm(futdat_f[4], ',',skipstart=1)
fut_nf_rcp85 = readdlm(futdat_f[5], ',',skipstart=1)

fut_hist_exc = readdlm(futdat_f_exc[1], ',',skipstart=1)
fut_ff_rcp45_exc = readdlm(futdat_f_exc[2], ',',skipstart=1)
fut_nf_rcp45_exc = readdlm(futdat_f_exc[3], ',',skipstart=1)
fut_ff_rcp85_exc = readdlm(futdat_f_exc[4], ',',skipstart=1)
fut_nf_rcp85_exc = readdlm(futdat_f_exc[5], ',',skipstart=1)


#### Densities exceedances
density(sum(fut_hist_exc,dims=1)[:]/10, label = "Hist",c=bcols[1])
density!(sum(fut_ff_rcp45_exc,dims=1)[:]/10, label = "FF rcp4.5",c=bcols[2])
density!(sum(fut_ff_rcp85_exc,dims=1)[:]/10, label = "FF rcp8.5",c=bcols[3])
title!("Densities Hist vs. FF")
ylabel!("Prob")
xlabel!("Exceedances")
png("./plot_future/dens_ff_exc_comp.png")


density(sum(fut_hist_exc,dims=1)[:]/10, label = "Hist",c=bcols[1])
density!(sum(fut_nf_rcp45_exc,dims=1)[:]/10, label = "NF rcp4.5",c=bcols[2])
density!(sum(fut_nf_rcp85_exc,dims=1)[:]/10, label = "NF rcp8.5",c=bcols[3])
title!("Densities Hist vs. NF")
ylabel!("Prob")
xlabel!("Exceedances")
png("./plot_future/dens_nf_exc_comp.png")



##### Densities concentrations
density(mean(fut_hist,dims=1)[:], label = "Hist",c=bcols[1],bandwidth=2)
density!(mean(fut_ff_rcp45,dims=1)[:], label = "FF rcp4.5",bandwidth=2,c=bcols[2])
density!(mean(fut_ff_rcp85,dims=1)[:], label = "FF rcp8.5",bandwidth=2,c=bcols[3])
title!("Densities Hist vs. FF")
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("./plot_future/dens_ff_conc_comp.png")


density(mean(fut_hist,dims=1)[:], label = "Hist",bandwidth=2,c=bcols[1])
density!(mean(fut_nf_rcp45,dims=1)[:], label = "NF rcp4.5",bandwidth=2,c=bcols[2])
density!(mean(fut_nf_rcp85,dims=1)[:], label = "NF rcp8.5",bandwidth=2,c=bcols[3])
title!("Densities Hist vs. NF")
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("./plot_future/dens_nf_conc_comp.png")


#### Boxplot exceedances
boxplot(sum(fut_hist_exc,dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(sum(fut_ff_rcp45_exc,dims=1)[:]/10, label = "FF rcp4.5",c=bcols[2])
boxplot!(sum(fut_ff_rcp85_exc,dims=1)[:]/10, label = "FF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. FF")
ylabel!("Exceedances")
png("./plot_future/box_ff_exc_comp.png")


boxplot(sum(fut_hist_exc,dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(sum(fut_nf_rcp45_exc,dims=1)[:]/10, label = "NF rcp4.5",c=bcols[2])
boxplot!(sum(fut_nf_rcp85_exc,dims=1)[:]/10, label = "NF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. NF")
ylabel!("Exceedances")
png("./plot_future/box_nf_exc_comp.png")



##### Boxplot concentrations
boxplot(mean(fut_hist,dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(mean(fut_ff_rcp45,dims=1)[:], label = "FF rcp4.5",c=bcols[2])
boxplot!(mean(fut_ff_rcp85,dims=1)[:], label = "FF rcp8.5",c=bcols[3])
title!("Boxplot Hist vs. FF")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
png("./plot_future/box_ff_conc_comp.png")


boxplot(mean(fut_hist,dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(mean(fut_nf_rcp45,dims=1)[:], label = "NF rcp4.5",c=bcols[2])
boxplot!(mean(fut_nf_rcp85,dims=1)[:], label = "NF rcp8.5",c=bcols[3])
title!("Boxplot Hist vs. NF")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
png("./plot_future/box_nf_conc_comp.png")


############
############
############
############
############ MAM
############
############
############
############

#### Densities exceedances
density(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
density!(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "FF rcp4.5",c=bcols[2])
density!(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "FF rcp8.5",c=bcols[3])
title!("Densities Hist vs. FF MAM")
ylabel!("Prob")
xlabel!("Exceedances")
png("./plot_future/dens_ff_exc_comp_mam.png")


density(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
density!(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "NF rcp4.5",c=bcols[2])
density!(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "NF rcp8.5",c=bcols[3])
title!("Densities Hist vs. NF MAM")
ylabel!("Prob")
xlabel!("Exceedances")
png("./plot_future/dens_nf_exc_comp_mam.png")



##### Densities concentrations
density(mean(fut_hist[mam_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
density!(mean(fut_ff_rcp45[mam_cesm_sub,:],dims=1)[:], label = "FF rcp4.5",c=bcols[2])
density!(mean(fut_ff_rcp85[mam_cesm_sub,:],dims=1)[:], label = "FF rcp8.5",c=bcols[3])
title!("Densities Hist vs. FF MAM")
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("./plot_future/dens_ff_conc_comp_mam.png")


density(mean(fut_hist[mam_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
density!(mean(fut_nf_rcp45[mam_cesm_sub,:],dims=1)[:], label = "NF rcp4.5",c=bcols[2])
density!(mean(fut_nf_rcp85[mam_cesm_sub,:],dims=1)[:], label = "NF rcp8.5",c=bcols[3])
title!("Densities Hist vs. NF MAM")
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("./plot_future/dens_nf_conc_comp_mam.png")


#### Boxplot exceedances
boxplot(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "FF rcp4.5",c=bcols[2])
boxplot!(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "FF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. FF MAM")
ylabel!("Exceedances")
png("./plot_future/box_ff_exc_comp_mam.png")


boxplot(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "NF rcp4.5",c=bcols[2])
boxplot!(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)[:]/10, label = "NF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. NF MAM")
ylabel!("Exceedances")
png("./plot_future/box_nf_exc_comp_mam.png")



##### Boxplot concentrations
boxplot(mean(fut_hist[mam_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(mean(fut_ff_rcp45[mam_cesm_sub,:],dims=1)[:], label = "FF rcp4.5",c=bcols[2])
boxplot!(mean(fut_ff_rcp85[mam_cesm_sub,:],dims=1)[:], label = "FF rcp8.5",c=bcols[3])
title!("Boxplot Hist vs. FF MAM")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
png("./plot_future/box_ff_conc_comp_mam.png")


boxplot(mean(fut_hist[mam_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(mean(fut_nf_rcp45[mam_cesm_sub,:],dims=1)[:], label = "NF rcp4.5",c=bcols[2])
boxplot!(mean(fut_nf_rcp85[mam_cesm_sub,:],dims=1)[:], label = "NF rcp8.5",c=bcols[3])
title!("Boxplot Hist vs. NF MAM")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
png("./plot_future/box_nf_conc_comp_mam.png")





############
############
############
############
############ JJA
############
############
############
############


#### Densities exceedances
density(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
density!(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "FF rcp4.5",c=bcols[2])
density!(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "FF rcp8.5",c=bcols[3])
title!("Densities Hist vs. FF JJA")
ylabel!("Prob")
xlabel!("Exceedances")
png("./plot_future/dens_ff_exc_comp_jja.png")


density(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
density!(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "NF rcp4.5",c=bcols[2])
density!(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "NF rcp8.5",c=bcols[3])
title!("Densities Hist vs. NF JJA")
ylabel!("Prob")
xlabel!("Exceedances")
png("./plot_future/dens_nf_exc_comp_jja.png")



##### Densities concentrations
density(mean(fut_hist[jja_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
density!(mean(fut_ff_rcp45[jja_cesm_sub,:],dims=1)[:], label = "FF rcp4.5",c=bcols[2])
density!(mean(fut_ff_rcp85[jja_cesm_sub,:],dims=1)[:], label = "FF rcp8.5",c=bcols[3])
title!("Densities Hist vs. FF JJA")
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("./plot_future/dens_ff_conc_comp_jja.png")


density(mean(fut_hist[jja_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
density!(mean(fut_nf_rcp45[jja_cesm_sub,:],dims=1)[:], label = "NF rcp4.5",c=bcols[2])
density!(mean(fut_nf_rcp85[jja_cesm_sub,:],dims=1)[:], label = "NF rcp8.5",c=bcols[3])
title!("Densities Hist vs. NF JJA")
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("./plot_future/dens_nf_conc_comp_jja.png")


#### Boxplot exceedances
boxplot(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "FF rcp4.5",c=bcols[2])
boxplot!(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "FF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. FF JJA")
ylabel!("Exceedances")
png("./plot_future/box_ff_exc_comp_jja.png")


boxplot(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "NF rcp4.5",c=bcols[2])
boxplot!(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)[:]/10, label = "NF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. NF JJA")
ylabel!("Exceedances")
png("./plot_future/box_nf_exc_comp_jja.png")



##### Boxplot concentrations
boxplot(mean(fut_hist[jja_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(mean(fut_ff_rcp45[jja_cesm_sub,:],dims=1)[:], label = "FF rcp4.5",c=bcols[2])
boxplot!(mean(fut_ff_rcp85[jja_cesm_sub,:],dims=1)[:], label = "FF rcp8.5",c=bcols[3])
title!("Boxplot Hist vs. FF JJA")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
png("./plot_future/box_ff_conc_comp_jja.png")


boxplot(mean(fut_hist[jja_cesm_sub,:],dims=1)[:], label = "Hist",c=bcols[1],framestyle=:box)
boxplot!(mean(fut_nf_rcp45[jja_cesm_sub,:],dims=1)[:], label = "NF rcp4.5",c=bcols[2])
boxplot!(mean(fut_nf_rcp85[jja_cesm_sub,:],dims=1)[:], label = "NF rcp8.5",c=bcols[3])
title!("Boxplot Hist vs. NF JJA")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
png("./plot_future/box_nf_conc_comp_jja.png")




##### Plot al stations with far future
# for i in 1:colsize
#     d1 = density(skipmissing(meas_aut[:,i]),label="Measurements")
#     density!(skipmissing(mod_wrf[:,i]),label="WRF")
#     density!(skipmissing(mod_camx[:,i]),label="CAMx")
#     title!("Model data;  " *meta_aut[:,"STATIONNAME"][i])
#     d2 = density(skipmissing(meas_aut[:,i]),label="Measurements")
#     density!(skipmissing(bias_wrf[:,i]),label="WRF")
#     density!(skipmissing(bias_camx[:,i]),label="CAMx")
#     title!("Biascorr data;  " *meta_aut[:,"STATIONNAME"][i])
#     plot(d1,d2,layout=laydr,size=(600,800))
#     ylabel!("Prob")
#     xlabel!("O₃ mda8 [μg/m³]")
#     xlims!(0,200)
#     ylims!(0,0.035)
#     png("./plots/density_meascomp/density_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
# end


# ##### Barplot exceedances

# bar([sum(fut_hist_exc)/10,sum(fut_nf_rcp45_exc)/10,sum(fut_ff_rcp45_exc)/10,sum(fut_nf_rcp85_exc)/10,sum(fut_ff_rcp85_exc)/10])
# bar([sum(fut_nf_rcp45_exc)/10,sum(fut_ff_rcp45_exc)/10])
# ylims!(0,4000)

bar([sum(fut_hist_exc[jja_cesm_sub,:])/10], label = "Hist",c=bcols[1],framestyle=:box)
bar!([sum(fut_nf_rcp45_exc[jja_cesm_sub,:])/10], label = "NF rcp4.5",c=bcols[2])
bar!([sum(fut_nf_rcp85_exc[jja_cesm_sub,:])/10], label = "NF rcp8.5",c=bcols[3])
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
title!("Boxplot Hist vs. NF JJA")
ylabel!("Exceedances")
png("./plot_future/box_nf_exc_comp_jja.png")




bar([1,2,3],[sum(fut_hist_exc[jja_cesm_sub,:])/10,sum(fut_nf_rcp45_exc[jja_cesm_sub,:])/10,sum(fut_nf_rcp85_exc[jja_cesm_sub,:])/10])


mean(sum(fut_hist_exc,dims=1)) / 10
mean(sum(fut_nf_rcp45_exc,dims=1)) / 10
mean(sum(fut_nf_rcp85_exc,dims=1)) / 10

mean(sum(fut_hist_exc,dims=1)) / 10
mean(sum(fut_ff_rcp45_exc,dims=1)) / 10
mean(sum(fut_ff_rcp85_exc,dims=1)) / 10

bar([1,2,3],[mean(sum(fut_hist_exc,dims=1)) / 10,mean(sum(fut_nf_rcp45_exc,dims=1)) / 10, mean(sum(fut_nf_rcp85_exc,dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,30)
title!("NF")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/exc_nf_ally.png")

bar([1,2,3],[mean(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)) / 10,mean(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)) / 10, mean(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,30)
title!("NF JJA")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/exc_nf_jja.png")

bar([1,2,3],[mean(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)) / 10,mean(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)) / 10, mean(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,30)
title!("NF MAM")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/exc_nf_mam.png")



bar([1,2,3],[mean(sum(fut_hist_exc,dims=1)) / 10,mean(sum(fut_nf_rcp45_exc,dims=1)) / 10, mean(sum(fut_nf_rcp85_exc,dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,30)
title!("FF")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/exc_ff_ally.png")

bar([1,2,3],[mean(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)) / 10,mean(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)) / 10, mean(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,30)
title!("FF JJA")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/exc_ff_jja.png")

bar([1,2,3],[mean(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)) / 10,mean(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)) / 10, mean(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,30)
title!("FF MAM")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/exc_ff_mam.png")




##### For 100 ugm/m³

ifelse.(fut_hist .> 100,1,0)

bar([1,2,3],[mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1)) / 10,mean(sum(ifelse.(fut_nf_rcp45 .> 100,1,0)
,dims=1)) / 10, mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,100)
title!("NF")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/100threh/exc_nf_ally.png")



bar([1,2,3],[mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1)) / 10,mean(sum(ifelse.(fut_nf_rcp45[jja_cesm_sub,:] .> 100,1,0)
,dims=1)) / 10, mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,100)
title!("NF JJA")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/100threh/exc_nf_jja.png")


bar([1,2,3],[mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1)) / 10,mean(sum(ifelse.(fut_nf_rcp45[mam_cesm_sub,:] .> 100,1,0)
,dims=1)) / 10, mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,100)
title!("NF MAM")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/100threh/exc_nf_mam.png")



bar([1,2,3],[mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1)) / 10,mean(sum(ifelse.(fut_ff_rcp45 .> 100,1,0)
,dims=1)) / 10, mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,100)
title!("FF")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/100threh/exc_ff_ally.png")



bar([1,2,3],[mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1)) / 10,mean(sum(ifelse.(fut_ff_rcp45[jja_cesm_sub,:] .> 100,1,0)
,dims=1)) / 10, mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,100)
title!("FF JJA")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/100threh/exc_ff_jja.png")


bar([1,2,3],[mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1)) / 10,mean(sum(ifelse.(fut_ff_rcp45[mam_cesm_sub,:] .> 100,1,0)
,dims=1)) / 10, mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1)) / 10],c=[bcols[1],bcols[2],bcols[3]],labels=["Measurements" "WRF" "CAMx"],legend=false,framestyle=:box)
xticks!([1,2,3],["Hist","RCP4.5","RCP8.5"])
ylims!(0,100)
title!("FF MAM")
ylabel!("Exceedances")
png("/home/cschmidt/projects/attaino3/plots/future_bar/100threh/exc_ff_mam.png")








