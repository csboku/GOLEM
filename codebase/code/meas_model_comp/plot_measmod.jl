using Plots,StatsPlots,NCDatasets,Statistics,CFTime,ProgressMeter,CSV,DataFrames,Dates,JLD,Missings,Measures,DelimitedFiles,RollingFunctions,ColorSchemes,Colors,Plots.PlotMeasures

cd(@__DIR__)

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end

default(palette = palette(:default))


linec1 = RGB(68/255,119/255,170/255)
linec2 = RGB(102/255,204/255,238/255)
linec3 = RGB(34/255,136/255,51/255)
linec4 = RGB(204/255,187/255,68/255)
linec5 = RGB(238/255,102/255,119/255)
linec6 = RGB(170/255,51/255,119/255)
linec7 = RGB(187/255,187/255,187/255)




season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]
season_son = ["September","October","November"]
season_djf = ["December","January","February"]

linec = ["#4477AA", "#EE6677", "#228833", "#CCBB442", "#66CCEE", "#AA3377", "#BBBBBB"]
#palette(linec[3:4])

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

getvecnarm = function(df)
    return(collect(skipmissing(vec(Matrix(df)))))
end

#gdf = groupby(bias_camx_exc_df,:year)
#valuecols(gdf)
#bias_camx_exc_yagg

yearly_agg = function (df,fun)
    gdf = groupby(df,:year;skipmissing=true)
    return(combine(gdf, names(gdf,Not([:date,:year])) .=> [fun]))
end


mean_stat_exc = function(vec)
    return(Int(round(mean(sum.(skipmissing.(eachcol(vec)))/10))))
end

replacemissing = function (df,val)
    for c ∈ eachcol(df)
        replace!(c, missing => val)
    end
    return(df)
end    

datapath = "/home/cschmidt/data/attain/measmod_csv/"



data_files = readdir(datapath)
data_f = readdir(datapath, join=true)

csv_f = data_f[occursin.(".csv",data_f)]

###### Wrie out processed files
##### TODO Read in data as matrix -> then mapslices
println.(csv_f)

csv_f[12]
csv_f[12:20]

bias_camx = CSV.read(csv_f[1],DataFrame)
bias_wrf = CSV.read(csv_f[3],DataFrame)
meas_aut = CSV.read(csv_f[9],DataFrame)
meta_aut = CSV.read(csv_f[11],DataFrame)
mod_camx = CSV.read(csv_f[12],DataFrame)
mod_wrf = CSV.read(csv_f[14],DataFrame)

bias_camx_exc = CSV.read(csv_f[2],DataFrame,missingstring="NA")
bias_wrf_exc = CSV.read(csv_f[4],DataFrame,missingstring="NA")
meas_aut_exc = CSV.read(csv_f[10],DataFrame,missingstring="NA")
mod_camx_exc = CSV.read(csv_f[13],DataFrame,missingstring="NA")
mod_wrf_exc = CSV.read(csv_f[15],DataFrame,missingstring="NA")


mat_bias_camx = Matrix(bias_camx)
mat_bias_wrf = Matrix(bias_wrf)
mat_meas_aut = Matrix(meas_aut)
mat_mod_camx = Matrix(mod_camx)
mat_mod_wrf = Matrix(mod_wrf)

mat_bias_camx_exc = Matrix(bias_camx_exc)
mat_bias_wrf_exc = Matrix(bias_wrf_exc)
mat_meas_aut_exc = Matrix(meas_aut_exc)
mat_mod_camx_exc = Matrix(mod_camx_exc)
mat_mod_wrf_exc = Matrix(mod_wrf_exc)

#### Types in meas aut exc are not good
#testdf = Missings.replace.(meas_aut_exc,0)

for c ∈ eachcol(meas_aut_exc)
    replace!(c, missing => 0)
end

meas_aut_exc



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



##### Create exceedacne dataframes with date for dataframe combine
meas_aut_exc_df = copy(meas_aut_exc)
meas_aut_exc_df[!,:date] = att_dates_meas
meas_aut_exc_df[!,:year] = Dates.value.(Year.(meas_aut_exc_df[:,:date]))

completecases(meas_aut_exc_df) |> plot

bias_camx_exc = replacemissing(bias_camx_exc,0)
bias_camx_exc_df = copy(bias_camx_exc)
bias_camx_exc_df[:,:date] = att_dates_cesm
bias_camx_exc_df[:,:year] = Dates.value.(Year.(bias_camx_exc_df[:,:date]))



bias_wrf_exc = replacemissing(bias_wrf_exc,0)
bias_wrf_exc_df = copy(bias_wrf_exc)
bias_wrf_exc_df[:,:date] = att_dates_cesm
bias_wrf_exc_df[:,:year] = Dates.value.(Year.(bias_wrf_exc_df[:,:date]))

mod_camx_exc_df = copy(mod_camx_exc)
mod_camx_exc_df[:,:date] = att_dates_cesm
mod_camx_exc_df[:,:year] = Dates.value.(Year.(mod_camx_exc_df[:,:date]))

mod_wrf_exc_df = copy(mod_wrf_exc)
mod_wrf_exc_df[:,:date] = att_dates_cesm
mod_wrf_exc_df[:,:year] = Dates.value.(Year.(mod_wrf_exc_df[:,:date]))

## get years of datetime stuff
#Groupby mit dataframes und einem unabhäängigen vector funktioniert nicht 
#combine(gdf, valuecols(gdf) .=> [minimum maximum sum])
#keepkeys::Bool=true : whether grouping columns of gd should be kept in the returned data frame.
gdf = groupby(bias_camx_exc_df,:year)
#valuecols(gdf)
bias_camx_exc_yagg = combine(gdf, names(gdf,Not([:date,:year])) .=> [sum])
bias_camx_exc_yagg
#bias_camx_exc_df[:,Not(:date)]

bias_camx_exc_yagg = yearly_agg(bias_camx_exc_df,sum)
meas_aut_exc_yagg = yearly_agg(meas_aut_exc_df,sum)
bias_wrf_exc_yagg = yearly_agg(bias_wrf_exc_df,sum)
mod_camx_exc_yagg = yearly_agg(mod_camx_exc_df,sum)
mod_wrf_exc_yagg = yearly_agg(mod_wrf_exc_df,sum)



barlay = @layout [a ; b c ; d e]
barlay_row = @layout [a b c d e ]

barplot_c = [:tomato2,:seagreen2,:tomato3,:seagreen3]

mean.(eachrow(meas_aut_exc_yagg)) |> bar
mean.(eachrow(bias_camx_exc_yagg)) |> bar
mean.(eachrow(bias_wrf_exc_yagg)) |> bar
mean.(eachrow(mod_camx_exc_yagg)) |> bar
mean.(eachrow(mod_wrf_exc_yagg)) |> bar  

meas_aut_exc_yagg[:,:year]

palette(:default)
hist_years = meas_aut_exc_yagg[:,:year][1:end-1]


b21=mean.(eachrow(yearly_agg(meas_aut_exc_df[s_jja(att_dates_meas),:],sum)[:,2:end]))
b22=mean.(eachrow(yearly_agg(mod_camx_exc_df[s_jja(att_dates_cesm),:],sum)[:,2:end]))
b23=mean.(eachrow(yearly_agg(mod_wrf_exc_df[s_jja(att_dates_cesm),:],sum)[:,2:end]))
b24=mean.(eachrow(yearly_agg(bias_camx_exc_df[s_jja(att_dates_cesm),:],sum)[:,2:end]))
b25=mean.(eachrow(yearly_agg(bias_wrf_exc_df[s_jja(att_dates_cesm),:],sum)[:,2:end]))



b31=mean.(eachrow(yearly_agg(meas_aut_exc_df[s_mam(att_dates_meas),:],sum)[:,2:end]))
b32=mean.(eachrow(yearly_agg(mod_camx_exc_df[s_mam(att_dates_cesm),:],sum)[:,2:end]))
b33=mean.(eachrow(yearly_agg(mod_wrf_exc_df[s_mam(att_dates_cesm),:],sum)[:,2:end]))
b34=mean.(eachrow(yearly_agg(bias_camx_exc_df[s_mam(att_dates_cesm),:],sum)[:,2:end]))
b35=mean.(eachrow(yearly_agg(bias_wrf_exc_df[s_mam(att_dates_cesm),:],sum)[:,2:end]))




#bar(meas_aut_exc_yagg[:,:year],sum.(eachrow(yearly_agg(meas_aut_exc_df[:,:],sum))))
#bar!(meas_aut_exc_yagg[:,:year],sum.(eachrow(yearly_agg(meas_aut_exc_df[s_mam(att_dates_meas),:],sum))))
#bar!(meas_aut_exc_yagg[:,:year],sum.(eachrow(yearly_agg(meas_aut_exc_df[s_jja(att_dates_meas),:],sum))))



##### Plot exceedances

density(agg_seas_df_sum(meas_aut_exc)/10,label="Measurements")
density!(agg_seas_df_sum(bias_camx_exc)/10, label = "CAMx")
density!(agg_seas_df_sum(bias_wrf_exc)/10, label = "WRF")

density(agg_seas_df_sum(meas_aut_exc)/10,label="Measurements")
density!(agg_seas_df_sum(mod_camx_exc)/10, label = "CAMx")
density!(agg_seas_df_sum(mod_wrf_exc)/10, label = "WRF")


##### Plot over whole Matrix



layp2 = @layout [a ; b] 
pd1 = density(skipmissing(getvec(meas_aut)),label="Measurements")
density!(skipmissing(getvec(mod_wrf)),label="WRF")
density!(skipmissing(getvec(mod_camx)),label="CAMx")
ylims!(0,0.025)
title!("model data")
pd2=density(skipmissing(getvec(meas_aut)),label="Measurements")
density!(skipmissing(getvec(bias_wrf)),label="WRF")
density!(skipmissing(getvec(bias_camx)),label ="CAMx")
ylims!(0,0.015)
title!("bias corrected")


plot(pd1,pd2,layout=layp2,size=(500,600),dpi=300)
ylabel!("Prob")
xlabel!("O₃ mda8 [μg/m³]")
png("measmod_dens_row.png")



layp2 = @layout [a  b] 
pd1 = density(skipmissing(getvec(meas_aut)),label="Measurements")
density!(skipmissing(getvec(mod_wrf)),label="WRF")
density!(skipmissing(getvec(mod_camx)),label="CAMx")
title!("model data")
ylims!(0,0.025)
pd2=density(skipmissing(getvec(meas_aut)),label="Measurements")
density!(skipmissing(getvec(bias_wrf)),label="WRF")
density!(skipmissing(getvec(bias_camx)),label ="CAMx")
ylims!(0,0.025)
title!("bias corrected")


plot(pd1,pd2,layout=layp2,size=(900,400),left_margin=5mm,bottom_margin=3.5mm,right_margin=1mm,framestyle=:box)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
xlims!(0,200)
ylims!(0,0.025)
png("measmod_dens_col.png")


####### do the same thing for the exceedances ????


###Plot Stations

colsize = size(bias_camx)[2]

# for i in 1:colsize
#     density(skipmissing(meas_aut[:,i]),label="Measurements")
#     density!(skipmissing(mod_wrf[:,i]),label="WRF")
#     density!(skipmissing(mod_camx[:,i]),label="CAMx")
#     title!("Model data;  " *meta_aut[:,"STATIONNAME"][i])
#     ylabel!("Prob")
#     xlabel!("O₃ mda8 [μg/m³]")
#     xlims!(0,200)
#     ylims!(0,0.035)
#     png("./plots/density_model/density_mod_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
# end

# for i in 1:colsize
#     density(skipmissing(meas_aut[:,i]),label="Measurements")
#     density!(skipmissing(bias_wrf[:,i]),label="WRF")
#     density!(skipmissing(bias_camx[:,i]),label="CAMx")
#     title!("Biascorr data;  " *meta_aut[:,"STATIONNAME"][i])
#     ylabel!("Prob")
#     xlabel!("O₃ mda8 [μg/m³]")
#     xlims!(0,200)
#     ylims!(0,0.035)
#     png("./plots/density_bias/density_bias_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
# end

###Panelplot
laydr = @layout [a ; b] 


for i in 1:colsize
    d1 = density(skipmissing(meas_aut[:,i]),label="Measurements",bandwidth=4,framestyle=:box,c=linec6)
    density!(skipmissing(mod_wrf[:,i]),label="WRF",bandwidth=4,c=linec1)
    density!(skipmissing(mod_camx[:,i]),label="CAMx",bandwidth=4,c=linec3)
    title!("Model;  " *meta_aut[:,"STATIONNAME"][i])
    annotate!(:topleft,"c)")
    d2 = density(skipmissing(meas_aut[:,i]),label="Measurements",bandwidth=4,framestyle=:box,c=linec6)
    density!(skipmissing(bias_wrf[:,i]),label="WRF",bandwidth=4,c=linec1)
    density!(skipmissing(bias_camx[:,i]),label="CAMx",bandwidth=4,c=linec3)
    title!("BC Model;  " *meta_aut[:,"STATIONNAME"][i])
    plot(d1,d2,layout=laydr,size=(600,800),left_margin=5mm)
    ylabel!("Probability")
    xlabel!("O₃ mda8 [μg/m³]")
    xlims!(0,200)
    ylims!(0,0.035)
    png("/home/cschmidt/projects/attaino3/plots/densities/stations/ann_c/density_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
end

##### Plot the selected stations



meas_aut



meta_aut[:,"station_type_of_area"] |> println
meta_aut[:,"type_of_station"]
names(meta_aut) |> println

##########
##########
########## Boxplots
##########
##########




layp2 = @layout [a ; b] 
pd1 = boxplot(skipmissing(getvec(meas_aut)),label="Measurements",legend=false)
boxplot!(skipmissing(getvec(mod_wrf)),label="WRF")
boxplot!(skipmissing(getvec(mod_camx)),label="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("model data")
pd2=boxplot(skipmissing(getvec(meas_aut)),label="Measurements", legend=false)
boxplot!(skipmissing(getvec(bias_wrf)),label="WRF")
boxplot!(skipmissing(getvec(bias_camx)),label ="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("bias corrected")


plot(pd1,pd2,layout=layp2,size=(500,600))
ylabel!("O₃ mda8 [μg/m³]")
png("measmod_box_row.png")



layp2 = @layout [a  b] 
pd1 = boxplot(skipmissing(getvec(meas_aut)),label="Measurements",legend=false)
boxplot!(skipmissing(getvec(mod_wrf)),label="WRF")
boxplot!(skipmissing(getvec(mod_camx)),label="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("model data")
pd2=boxplot(skipmissing(getvec(meas_aut)),label="Measurements", legend=false)
boxplot!(skipmissing(getvec(bias_wrf)),label="WRF")
boxplot!(skipmissing(getvec(bias_camx)),label ="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("bias corrected")


plot(pd1,pd2,layout=layp2,size=(800,500),left_margin=4mm,right_margin=2mm)
ylabel!("O₃ mda8 [μg/m³]")
png("measmod_box_col.png")


####### do the same thing for the exceedances ????


###############
###############
############### Violin Plots
###############
###############

layp2 = @layout [a ; b] 
pd1 = violin(skipmissing(getvec(meas_aut)),label="Measurements",legend=false)
violin!(skipmissing(getvec(mod_wrf)),label="WRF")
violin!(skipmissing(getvec(mod_camx)),label="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("model data")
pd2=violin(skipmissing(getvec(meas_aut)),label="Measurements", legend=false)
violin!(skipmissing(getvec(bias_wrf)),label="WRF")
violin!(skipmissing(getvec(bias_camx)),label ="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("bias corrected")


plot(pd1,pd2,layout=layp2,size=(500,600))
ylabel!("O₃ mda8 [μg/m³]")
png("measmod_viol_row.png")



layp2 = @layout [a  b] 
pd1 = violin(skipmissing(getvec(meas_aut)),label="Measurements",legend=false)
violin!(skipmissing(getvec(mod_wrf)),label="WRF")
violin!(skipmissing(getvec(mod_camx)),label="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("model data")
pd2=violin(skipmissing(getvec(meas_aut)),label="Measurements", legend=false)
violin!(skipmissing(getvec(bias_wrf)),label="WRF")
violin!(skipmissing(getvec(bias_camx)),label ="CAMx")
xticks!([1,2,3],["Meas","WRF","CAMx"])
ylims!(0,250)
title!("bias corrected")


plot(pd1,pd2,layout=layp2,size=(500,600))
ylabel!("O₃ mda8 [μg/m³]")
png("measmod_viol_col.png")





# for i in 1:colsize
#     boxplot(skipmissing(meas_aut[:,i]),label="Measurements")
#     boxplot!(skipmissing(mod_wrf[:,i]),label="WRF")
#     boxplot!(skipmissing(mod_camx[:,i]),label="CAMx")
#     title!("Model data;  " *meta_aut[:,"STATIONNAME"][i])
#     ylabel!("O₃ mda8 [μg/m³]")
#     ylims!(0,250)
#     xticks!([1,2,3],["Meas","WRF","CAMx"])
#     png("./plots/box_model/box_mod_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
# end

# for i in 1:colsize
#     boxplot(skipmissing(meas_aut[:,i]),label="Measurements")
#     boxplot!(skipmissing(bias_wrf[:,i]),label="WRF")
#     boxplot!(skipmissing(bias_camx[:,i]),label="CAMx")
#     title!("Biascorr data;  " *meta_aut[:,"STATIONNAME"][i])
#     ylabel!("O₃ mda8 [μg/m³]")
#     ylims!(0,250)
#     xticks!([1,2,3],["Meas","WRF","CAMx"])
#     png("./plots/box_bias/box_bias_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
# end

### Panelplot
laybr = @layout [a ; b] 

for i in 1:colsize
    b1 = boxplot(skipmissing(meas_aut[:,i]),label="Measurements")
    boxplot!(skipmissing(mod_wrf[:,i]),label="WRF")
    boxplot!(skipmissing(mod_camx[:,i]),label="CAMx")
    title!("Model data;  " *meta_aut[:,"STATIONNAME"][i])
    b2 = boxplot(skipmissing(meas_aut[:,i]),label="Measurements")
    boxplot!(skipmissing(bias_wrf[:,i]),label="WRF")
    boxplot!(skipmissing(bias_camx[:,i]),label="CAMx")
    title!("Biascorr data;  " *meta_aut[:,"STATIONNAME"][i])
    plot(b1,b2,layout=laybr,size=(600,800))
    ylabel!("O₃ mda8 [μg/m³]")
    ylims!(0,250)
    xticks!([1,2,3],["Meas","WRF","CAMx"])
    png("./plots/boxplot_meascomp/box_"*meta_aut[:,"station_european_code"][i]*"_"*meta_aut[:,"type_of_station"][i]*"_"*meta_aut[:,"station_type_of_area"][i]*".png")
end



plot(att_dates_meas,sum.(skipmissing.(eachrow(meas_aut_exc))))
plot!(sum.(skipmissing.(eachrow(bias_wrf_exc))))
plot!(sum.(skipmissing.(eachrow(bias_camx_exc))))





#######
#######
####### Plot exceedacne timeseries
#######
#######
att_date_years = Date.(unique(Year.(att_dates_cesm)))
string([2006:2017;])


plot(att_dates_meas,cumsum(sum.(skipmissing.(eachrow(meas_aut_exc)))),label="Measurements",xticks=(att_date_years,string.([2006:2017;])))
plot!(att_dates_cesm,cumsum(sum.(skipmissing.(eachrow(bias_wrf_exc)))),label="WRF")
plot!(att_dates_cesm,cumsum(sum.(skipmissing.(eachrow(bias_camx_exc)))),label="CAMx")
ylabel!("Cumulative Exceedances")
title!("Cumulative Exceedances;  biascorrected")
png("cumsum_bias.png")


plot(att_dates_meas,cumsum(sum.(skipmissing.(eachrow(meas_aut_exc)))),label="Measurements",xticks=(att_date_years,string.([2006:2017;])))
plot!(att_dates_cesm,cumsum(sum.(skipmissing.(eachrow(mod_wrf_exc)))),label="WRF")
plot!(att_dates_cesm,cumsum(sum.(skipmissing.(eachrow(mod_camx_exc)))),label="CAMx")
ylabel!("Cumulative Exceedances")
title!("Cumulative Exceedances;  raw model data")
png("cumsum_model.png")




###########
###########
###########
###########     PAPER FIGURES
###########
###########
###########
###########


#### FIG1


##a)


density(sum.(skipmissing.(eachcol(meas_aut_exc)))/10,label="Measurements",size=(600,400))
density!(sum.(skipmissing.(eachcol(mod_wrf_exc)))/10,label="WRF")
density!(sum.(skipmissing.(eachcol(mod_camx_exc)))/10,label="CAMx")
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("Density of hist exdays raw model over 10Years")
ylims!(-0.002,0.15)
png("fig1a.png")

density(sum.(skipmissing.(eachcol(meas_aut_exc)))/10,label="Measurements",size=(600,400))
density!(sum.(skipmissing.(eachcol(bias_wrf_exc)))/10,label="WRF")
density!(sum.(skipmissing.(eachcol(bias_camx_exc)))/10,label="CAMx")
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("Density of hist exdays biascorrected over 10Years")
ylims!(-0.002,0.15)
png("fig1b.png")



boxplot(sum.(skipmissing.(eachcol(meas_aut_exc)))/10,label="Measurements",size=(600,400))
boxplot!(sum.(skipmissing.(eachcol(mod_wrf_exc)))/10,label="WRF")
boxplot!(sum.(skipmissing.(eachcol(mod_camx_exc)))/10,label="CAMx")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Meas","WRF","CAMx"])
title!("Boxplot of hist exdays raw model over 10Years")
png("fig1d.png")

boxplot(sum.(skipmissing.(eachcol(meas_aut_exc)))/10,label="Measurements",size=(600,400))
boxplot!(sum.(skipmissing.(eachcol(bias_wrf_exc)))/10,label="WRF")
boxplot!(sum.(skipmissing.(eachcol(bias_camx_exc)))/10,label="CAMx")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Meas","WRF","CAMx"])
title!("Boxplot of hist exdays raw model over 10Years")
png("fig1e.png")

### Fig 2 10 Year exceedance days annual
meas_aut
boxplot(mean.(skipmissing.(eachcol(meas_aut)))/10,label="Measurements",size=(600,400))
boxplot!(mean.(skipmissing.(eachcol(bias_wrf)))/10,label="Measurements",size=(600,400))


########## BOXPLOT mda8 conc
p1 = boxplot(skipmissing(mat_meas_aut),label="Measurements",legend=false,framestyle = :box)
boxplot!(skipmissing(mat_mod_wrf),label="WRF")
boxplot!(skipmissing(mat_mod_camx),label="CAMx")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Meas","WRF","CAMx"])
png("box_mda8_mod_all")

p2 = boxplot(skipmissing(mat_meas_aut),label="Measurements",legend=false,framestyle=:box)
boxplot!(skipmissing(mat_bias_wrf),label="WRF")
boxplot!(skipmissing(mat_bias_camx),label="CAMx")
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3],["Meas","BC WRF","BC CAMx"])
png("box_mda8_bias_all")


mean_stat_exc(meas_aut_exc)
std_cols = cgrad(:default,10,categorical=true)
std_cols=palette(:default)

p3 = bar([mean_stat_exc(meas_aut_exc),mean_stat_exc(mod_wrf_exc),mean_stat_exc(mod_camx_exc)],c=[linec6,linec3,linec2],legend=false,framestyle=:box)
ylims!(0,40)
ylabel!("Exceedances")
xticks!([1,2,3],["Meas","WRF","CAMx"])
annotate!(:topleft,"c)")
png("/home/cschmidt/projects/attaino3/plots/barplots/bar_model_c")
p3


p4 = bar([mean_stat_exc(meas_aut_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],c=std_cols[1:3],legend=false,framestyle=:box)
ylims!(0,40)
ylabel!("Exceedances")
xticks!([1,2,3],["Meas","BC WRF","BC CAMx"])
annotate!(:topleft,"d)")
png("/home/cschmidt/projects/attaino3/plots/barplots/bar_bias_d")
######## Look at future data

plot(p1,p2,p3,p4,layout=4,size=(800,800))
png("bias_validation_panel")

future_datapath = "/home/cschmidt/data/attain_future_csv/mda8"

futdat_files = readdir(future_datapath)
futdat_f = readdir(future_datapath,join=true)

futdat_f[3]

fut_hist = CSV.read(futdat_f[1], DataFrame)
fut_ff_rcp45 = CSV.read(futdat_f[2], DataFrame)
fut_nf_rcp45 = CSV.read(futdat_f[3], DataFrame)
fut_ff_rcp85 = CSV.read(futdat_f[4], DataFrame)
fut_nf_rcp85 = CSV.read(futdat_f[5], DataFrame)





##################################################################
##################################################################
##################################################################
##################################################################
########### Plot matrix
##################################################################
##################################################################
##################################################################
##################################################################

spmean = function(ds)
    ds_spmean = mapslices(x->mean(skipmissing(x)),ds,dims = [1])[:]
    return ds_spmean
end

spsum = function(ds)
    ds_spmean = mapslices(x->sum(skipmissing(x)),ds,dims = [1])[:]
    return ds_spmean
end

tmean = function(ds)
    ds_spmean = mapslices(x->mean(skipmissing(x)),ds,dims = [2])[:]
    return ds_spmean
end

tsum = function(ds)
    ds_spmean = mapslices(x->sum(skipmissing(x)),ds,dims = [2])[:]
    return ds_spmean
end

##### Get indizes of background stations
names(meta_aut)
back_sub = meta_aut[:,:type_of_station] .== "Background"

meta_aut[:,:STATIONNAME]

meta_aut[back_sub,:]

wrf_grid = Dataset("/home/cschmidt/data/attain/model_output/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_cropped.nc")
wrf_grid_o3 = wrf_grid["O3"]
camx_grid = Dataset("/home/cschmidt/data/attain/model_output/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda_cropped.nc")
camx_grid_o3 = camx_grid["O3"]

wrf_bias_grid = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
wrf_bias_grid_o3 = wrf_bias_grid["O3"]

camx_bias_grid = Dataset("/home/cschmidt/data/attain/bias_corr_output_mda8/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
camx_bias_grid_o3 = camx_bias_grid["O3"]


density(getvecnarm(meas_aut[:,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(mod_wrf[:,back_sub]), label = "WRFChem",bandwidth=2,c=linec1)
density!(getvecnarm(mod_camx[:,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
density!(na_rm(vec(wrf_grid_o3)),label="WRFChem AUT",ls=:dash,bandwidth=2,c=linec1)
density!(na_rm(vec(camx_grid_o3)),label="CAMx AUT",ls=:dash,bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("Model")
annotate!(:topleft,"a)")
ylims!(-0.001,0.025)
png("/home/cschmidt/projects/attaino3/plots/densities/model_dens.png")
png("1_s.png")

density(getvecnarm(meas_aut[:,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(bias_wrf[:,back_sub]), label = "WRFChem BC",bandwidth=2,c=linec1)
density!(getvecnarm(bias_camx[:,back_sub]), label = "CAMx BC",bandwidth=2,c=linec3)
density!(na_rm(vec(wrf_bias_grid_o3)),label="WRFChem BC AUT",ls=:dash,bandwidth=2,c=linec1)
density!(na_rm(vec(camx_bias_grid_o3)),label="CAMx BC AUT",ls=:dash,bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("BC Model")
annotate!(:topleft,"b)")
ylims!(-0.001,0.025)
png("/home/cschmidt/projects/attaino3/plots/densities/bias_dens.png")
png("2_s.png")


boxplot(getvecnarm(meas_aut[:,back_sub]),label="Measurements",legend=false,outliers=false,whisker_range=1,framestyle=:box,c=linec5)
boxplot!(getvecnarm(mod_wrf[:,back_sub]), label = "WRF",outliers=false,whisker_range=1,c=linec1)
boxplot!(getvecnarm(mod_camx[:,back_sub]), label = "CAMx",outliers=false,whisker_range=1,c=linec3)
#boxplot!(getvecnarm(bias_wrf[:,back_sub]), label = "WRF",outliers=false,whisker_range=1)
#boxplot!(getvecnarm(bias_camx[:,back_sub]), label = "CAMx",outliers=false,whisker_range=1)
xticks!([1,2,3,4,5],["Meas","WRF","CAMx","WRF","CAMx"])
ylims!(-5,150)
ylabel!("O₃ mda8 [μg/m³]")
title!("Model")
annotate!(:topleft,"c)")
png("/home/cschmidt/projects/attaino3/plots/boxplots/model_box.png")
png("3.png")

boxplot(getvecnarm(meas_aut[:,back_sub]),label="Measurements",legend=false,outliers=false,whisker_range=1,framestyle=:box,c=linec5)
#boxplot!(getvecnarm(mod_wrf[:,back_sub]), label = "WRF",outliers=false,whisker_range=1)
#boxplot!(getvecnarm(mod_camx[:,back_sub]), label = "CAMx",outliers=false,whisker_range=1)
boxplot!(getvecnarm(bias_wrf[:,back_sub]), label = "WRF",outliers=false,whisker_range=1,c=linec1)
boxplot!(getvecnarm(bias_camx[:,back_sub]), label = "CAMx",outliers=false,whisker_range=1,c=linec3)
xticks!([1,2,3,4,5],["Meas","WRF","CAMx"])
ylims!(-5,150)
ylabel!("O₃ mda8 [μg/m³]")
title!("BC Model")
annotate!(:topleft,"d)")
png("/home/cschmidt/projects/attaino3/plots/boxplots/model_bc_box.png")

png("4.png")



sbdata_djf = hcat(mean(spmean(mat_meas_aut[djf_meas_sub,:])),mean(spmean(mat_mod_wrf[djf_cesm_sub,:])),mean(spmean(mat_mod_camx[djf_cesm_sub,:])))
sbdata_mam = hcat(mean(spmean(mat_meas_aut[mam_meas_sub,:])),mean(spmean(mat_mod_wrf[mam_cesm_sub,:])),mean(spmean(mat_mod_camx[mam_cesm_sub,:])))
sbdata_jja = hcat(mean(spmean(mat_meas_aut[jja_meas_sub,:])),mean(spmean(mat_mod_wrf[jja_cesm_sub,:])),mean(spmean(mat_mod_camx[jja_cesm_sub,:])))
sbdata_son = hcat(mean(spmean(mat_meas_aut[son_meas_sub,:])),mean(spmean(mat_mod_wrf[son_cesm_sub,:])),mean(spmean(mat_mod_camx[son_cesm_sub,:])))
sbdata_conc = vcat(sbdata_djf,sbdata_mam,sbdata_jja,sbdata_son)


groupedbar(sbdata_conc,stack=true,labels=["Measurements" "WRF" "CAMx"],framestyle=:box,fillcolor=[linec5 linec1 linec3])
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3,4],["DJF","MAM","JJA","SON"])
ylims!(0,120)
title!("Model")
png("5.png")

sbdata_djf = hcat(mean(spsum(mat_meas_aut_exc[djf_meas_sub,:])),mean(spsum(mat_mod_wrf_exc[djf_cesm_sub,:])),mean(spsum(mat_mod_camx_exc[djf_cesm_sub,:])))
sbdata_mam = hcat(mean(spsum(mat_meas_aut_exc[mam_meas_sub,:])),mean(spsum(mat_mod_wrf_exc[mam_cesm_sub,:])),mean(spsum(mat_mod_camx_exc[mam_cesm_sub,:])))
sbdata_jja = hcat(mean(spsum(mat_meas_aut_exc[jja_meas_sub,:])),mean(spsum(mat_mod_wrf_exc[jja_cesm_sub,:])),mean(spsum(mat_mod_camx_exc[jja_cesm_sub,:])))
sbdata_son = hcat(mean(spsum(mat_meas_aut_exc[son_meas_sub,:])),mean(spsum(mat_mod_wrf_exc[son_cesm_sub,:])),mean(spsum(mat_mod_camx_exc[son_cesm_sub,:])))
sbdata_exc = vcat(sbdata_djf,sbdata_mam,sbdata_jja,sbdata_son) ./ 10

groupedbar(sbdata_exc,stack=true,labels=["Measurements" "WRF" "CAMx"],framestyle=:box,fillcolor=[linec5 linec1 linec3])
ylabel!("Exceedances")
xticks!([1,2,3,4],["DJF","MAM","JJA","SON"])
ylims!(0,20)
title!("Model")
png("6.png")


sbdata_djf = hcat(mean(spmean(mat_meas_aut[djf_meas_sub,:])),mean(spmean(mat_bias_wrf[djf_cesm_sub,:])),mean(spmean(mat_bias_camx[djf_cesm_sub,:])))
sbdata_mam = hcat(mean(spmean(mat_meas_aut[mam_meas_sub,:])),mean(spmean(mat_bias_wrf[mam_cesm_sub,:])),mean(spmean(mat_bias_camx[mam_cesm_sub,:])))
sbdata_jja = hcat(mean(spmean(mat_meas_aut[jja_meas_sub,:])),mean(spmean(mat_bias_wrf[jja_cesm_sub,:])),mean(spmean(mat_bias_camx[jja_cesm_sub,:])))
sbdata_son = hcat(mean(spmean(mat_meas_aut[son_meas_sub,:])),mean(spmean(mat_bias_wrf[son_cesm_sub,:])),mean(spmean(mat_bias_camx[son_cesm_sub,:])))
sbdata_conc_bias = vcat(sbdata_djf,sbdata_mam,sbdata_jja,sbdata_son)


groupedbar(sbdata_conc_bias,stack=true,labels=["Measurements" "WRF" "CAMx"],framestyle=:box,fillcolor=[linec5 linec1 linec3])
ylabel!("O₃ mda8 [μg/m³]")
xticks!([1,2,3,4],["DJF","MAM","JJA","SON"])
ylims!(0,120)
title!("BC Model")
png("7.png")


sbdata_djf = hcat(mean(spsum(mat_meas_aut_exc[djf_meas_sub,:])),mean(spsum(mat_bias_wrf_exc[djf_cesm_sub,:])),mean(spsum(mat_bias_camx_exc[djf_cesm_sub,:])))
sbdata_mam = hcat(mean(spsum(mat_meas_aut_exc[mam_meas_sub,:])),mean(spsum(mat_bias_wrf_exc[mam_cesm_sub,:])),mean(spsum(mat_bias_camx_exc[mam_cesm_sub,:])))
sbdata_jja = hcat(mean(spsum(mat_meas_aut_exc[jja_meas_sub,:])),mean(spsum(mat_bias_wrf_exc[jja_cesm_sub,:])),mean(spsum(mat_bias_camx_exc[jja_cesm_sub,:])))
sbdata_son = hcat(mean(spsum(mat_meas_aut_exc[son_meas_sub,:])),mean(spsum(mat_bias_wrf_exc[son_cesm_sub,:])),mean(spsum(mat_bias_camx_exc[son_cesm_sub,:])))
sbdata_exc_bias = vcat(sbdata_djf,sbdata_mam,sbdata_jja,sbdata_son) ./ 10

groupedbar(sbdata_exc_bias,stack=true,labels=["Measurements" "WRF" "CAMx"],framestyle=:box,fillcolor=[linec5 linec1 linec3])
ylabel!("Exceedances")
xticks!([1,2,3,4],["DJF","MAM","JJA","SON"])
ylims!(0,20)
title!("BC Model")
png("8.png")

############ Check seasonal densities

density(getvecnarm(meas_aut[djf_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(mod_wrf[djf_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(mod_camx[djf_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("DJF Model")
ylims!(0,0.04)
png("d_m_djf.png")

density(getvecnarm(meas_aut[djf_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(bias_wrf[djf_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(bias_camx[djf_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("DJF BC Model")
ylims!(0,0.04)
png("d_b_djf.png")

density(getvecnarm(meas_aut[mam_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(mod_wrf[mam_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(mod_camx[mam_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("MAM Model")
ylims!(0,0.04)
png("d_m_mam.png")

density(getvecnarm(meas_aut[mam_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(bias_wrf[mam_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(bias_camx[mam_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("MAM BC Model")
ylims!(0,0.04)
png("d_b_mam.png")


density(getvecnarm(meas_aut[jja_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(mod_wrf[jja_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(mod_camx[jja_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("JJA Model")
ylims!(0,0.04)
png("d_m_jja.png")

density(getvecnarm(meas_aut[jja_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(bias_wrf[jja_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(bias_camx[jja_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("JJA BC Model")
ylims!(0,0.04)
png("d_b_jja.png")

density(getvecnarm(meas_aut[son_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(mod_wrf[son_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(mod_camx[son_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("SON Model")
ylims!(0,0.04)
png("d_m_son.png")

density(getvecnarm(meas_aut[son_meas_sub,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=linec5)
density!(getvecnarm(bias_wrf[son_cesm_sub,back_sub]), label = "WRF",bandwidth=2,c=linec1)
density!(getvecnarm(bias_camx[son_cesm_sub,back_sub]), label = "CAMx",bandwidth=2,c=linec3)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("SON BC Model")
ylims!(0,0.04)
png("d_b_son.png")

########### Read in ERA5 data
#default(palette = palette(:vibrant,3))

era_files = readdir("/home/cschmidt/data/measmod_csv/",join=true)
era_f = readdir("/home/cschmidt/data/measmod_csv/")

era_files = era_files[occursin.("era",era_f)]
era_f = era_f[occursin.("era",era_f)]


bias_camx_era_exc = readdlm(era_files[1],',',skipstart=1)
bias_camx_era = readdlm(era_files[2],',',skipstart=1)
mod_camx_era_exc = readdlm(era_files[3],',',skipstart=1)
mod_camx_era = readdlm(era_files[4],',',skipstart=1)

bias_wrf_era_exc = readdlm(era_files[5],',',skipstart=1)
bias_wrf_era = readdlm(era_files[6],',',skipstart=1)
mod_wrf_era_exc = readdlm(era_files[7],',',skipstart=1)
mod_wrf_era = readdlm(era_files[8],',',skipstart=1)


density(getvecnarm(meas_aut[:,back_sub]),label="Measurements",bandwidth=2,framestyle=:box)
density!(vec(bias_camx_era[:,back_sub]),label="Bias CAMX",bandwidth=2)
density!(vec(bias_wrf_era[:,back_sub]),label="Bias WRF",bandwidth=2)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
title!("Model data")
annotate!(0,0.020,"a)")
ylims!(-0.0005,0.025)


na_rm

density(na_rm(vec(mat_meas_aut)))
density!(na_rm(vec(mat_bias_wrf)))
density!(na_rm(vec(mat_bias_camx)))

density(spmean(mat_meas_aut))
density!(spmean(mat_bias_camx))
density!(spmean(mat_bias_wrf))

########## Test CAMx CESM diff
camx_test = readdlm("/home/cschmidt/data/measmod_csv/proc/camx_mda8_cesm_hist_statmatch_new_fin.csv",',',skipstart=1)


density(na_rm(vec(mat_meas_aut)))
density!(na_rm(vec(mat_bias_camx)))
density!(na_rm(vec(camx_test)))

mod_camx
bias_camx


cesm_dayyear = dayofyear.(att_dates["cesm_dates"])
meas_dayyear = dayofyear.(att_dates_meas)

meas_aut_d = insertcols(meas_aut,1,:day => meas_dayyear)
meas_aut_d = coalesce.(meas_aut_d, 50)
meas_aut_d_g = groupby(meas_aut_d,:day)
meas_aut_ti  = combine(meas_aut_d_g, valuecols(meas_aut_d_g) .=> mean) 
meas_aut_ti


mod_camx_d = insertcols(mod_camx,1,:day => cesm_dayyear)
mod_camx_d_g = groupby(mod_camx_d,:day)
mod_camx_ti = combine(mod_camx_d_g, valuecols(mod_camx_d_g) .=> mean) 
mod_camx_ti[:,2:end]


mod_wrf_d = insertcols(mod_wrf,1,:day => cesm_dayyear)
mod_wrf_d_g = groupby(mod_wrf_d,:day)
mod_wrf_ti = combine(mod_wrf_d_g, valuecols(mod_wrf_d_g) .=> mean) 
mod_camx_ti[:,2:end]

bias_wrf_d = insertcols(bias_wrf,1,:day => cesm_dayyear)
bias_wrf_d_g = groupby(bias_wrf_d,:day)
bias_wrf_ti = combine(bias_wrf_d_g, valuecols(bias_wrf_d_g) .=> mean) 
bias_wrf_ti[:,2:end]

bias_camx_d = insertcols(bias_camx,1,:day => cesm_dayyear)
bias_camx_d_g = groupby(bias_camx_d,:day)
bias_camx_ti = combine(bias_camx_d_g, valuecols(bias_camx_d_g) .=> mean) 
bias_camx_ti[:,2:end]



plot(mean.(eachrow(meas_aut_ti[:,2:end])),label="meas")
plot!(mean.(eachrow(mod_camx_ti[:,2:end])),label="CAMx")
plot!(mean.(eachrow(mod_wrf_ti[:,2:end])),label ="WRF")

plot(mean.(eachrow(meas_aut_ti[:,2:end])),label="meas")
plot!(mean.(eachrow(bias_camx_ti[:,2:end])),label="CAMx bias")
plot!(mean.(eachrow(bias_wrf_ti[:,2:end])),label ="WRF bias")



plot(rollmean(mean.(eachrow(meas_aut_ti[:,2:end])),7),label="meas")
plot!(rollmean(mean.(eachrow(mod_camx_ti[:,2:end])),7),label="CAMx")
plot!(rollmean(mean.(eachrow(mod_wrf_ti[:,2:end])),7),label ="WRF")
ylabel!("O₃ mda8 [μg/m³]")
xlabel!("Day of the year")
png("annual_o3")

plot(rollmean(mean.(eachrow(meas_aut_ti[:,2:end])),7),label="meas")
plot!(rollmean(mean.(eachrow(bias_camx_ti[:,2:end])),7),label="CAMx bias")
plot!(rollmean(mean.(eachrow(bias_wrf_ti[:,2:end])),7),label ="WRF bias")
ylabel!("O₃ mda8 [μg/m³]")
xlabel!("Day of the year")
png("annual_o3_bias")

plot(rollmean(mean.(eachrow(meas_aut_ti[:,2:end])),7))

GR()
####### Final Plots new
# Density p1
pap_c=["#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7"]
pap_c=palette(:Dark2_3)
pap_cd = [RGB(0.7*pap_c[1].r, 0.7*pap_c[1].g, 0.7*pap_c[1].b),RGB(0.7*pap_c[2].r, 0.7*pap_c[2].g, 0.7*pap_c[2].b),RGB(0.7*pap_c[3].r, 0.7*pap_c[3].g, 0.7*pap_c[3].b)]



density(getvecnarm(meas_aut[:,back_sub]),label="Obs",bandwidth=2,framestyle=:box,c=pap_c[1],dpi=150,legendfontsize=10,lw=2,tickfontsize=10,guidefontsize=12)
density!(getvecnarm(mod_wrf[:,back_sub]), label = "WRFChem_s",bandwidth=2,c=pap_c[2],lw=2)
density!(getvecnarm(mod_camx[:,back_sub]), label = "CAMx_s",bandwidth=2,c=pap_c[3],lw=2)
density!(na_rm(vec(wrf_grid_o3)),label="WRFChem*",ls=:dash,bandwidth=2,c=pap_c[2],lw=2)
density!(na_rm(vec(camx_grid_o3)),label="CAMx*",ls=:dash,bandwidth=2,c=pap_c[3],lw=2)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
#title!("Model")
annotate!(:topleft,"a)")
ylims!(-0.001,0.025)
p1 = ans


density(getvecnarm(meas_aut[:,back_sub]),label="Measurements",bandwidth=2,framestyle=:box,c=pap_c[1],dpi=150,legendfontsize=8,lw=2,legend=false,tickfontsize=10,labelsize=10,guidefontsize=12)
density!(getvecnarm(bias_wrf[:,back_sub]), label = "WRFChem BC",bandwidth=2,c=pap_cd[2],lw=2)
density!(getvecnarm(bias_camx[:,back_sub]), label = "CAMx BC",bandwidth=2,c=pap_cd[3],lw=2)
density!(na_rm(vec(wrf_bias_grid_o3)),label="WRFChem BC AUT",ls=:dash,bandwidth=2,c=pap_cd[2],lw=2)
density!(na_rm(vec(camx_bias_grid_o3)),label="CAMx BC AUT",ls=:dash,bandwidth=2,c=pap_cd[3],lw=2)
ylabel!("Probability")
xlabel!("O₃ mda8 [μg/m³]")
#title!("BC Model")
annotate!(:topleft,"b)")
ylims!(-0.001,0.025)
p2=ans

p3 = bar([mean_stat_exc(meas_aut_exc),mean_stat_exc(mod_wrf_exc),mean_stat_exc(mod_camx_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],c=[pap_c[1],pap_c[2],pap_c[3],pap_cd[2],pap_cd[3]],legend=false,framestyle=:box,dpi=150,tickfontsize=10,guidefontsize=12)
ylims!(0,40)
ylabel!("Exceedances")
xticks!([1,2,3,4,5],["Obs","WRFChem","CAMx","WRFChem_QMC","CAMx_QMC"])
annotate!(:topleft,"c)")
#png("/home/cschmidt/projects/attaino3/plots/barplots/bar_model_c")
p3


p4 = bar([mean_stat_exc(meas_aut_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],c=c=[pap_c[1],pap_c[2],pap_c[3]],legend=false,framestyle=:box,dpi=150,guidefontsize=12)
ylims!(0,40)
ylabel!("Exceedances")
xticks!([1,2,3],["Meas","BC WRF","BC CAMx"])
annotate!(:topleft,"d)")
#png("/home/cschmidt/projects/attaino3/plots/barplots/bar_bias_d")




layp4 = @layout [grid(1,2) ;  b] 

#plot(p1,p2,p3,p4,layout=4,size=(800,800))


plot(p1,p2,p3,p4,format = lay1 , size=(1000,650) ,dpi=150)
savefig("/home/cschmidt/projects/attaino3/plots/bias_validation.png")


plot(p1,p2,p3,layout=layp4  , size=(1000,650) ,dpi=150,left_margin=5mm)
savefig("/home/cschmidt/projects/attaino3/plots/bias_validation.png")
##### Plot stations

