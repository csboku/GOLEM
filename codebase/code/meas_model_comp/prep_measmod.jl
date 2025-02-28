using Plots,StatsPlots,NCDatasets,Statistics,CFTime,ProgressMeter,CSV,DataFrames,Dates


cd(@__DIR__)

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end



season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]

s_jja = function(d)
    return(findall(in(season_jja).(monthname.(d))))
end


s_mam = function(d)
    return(findall(in(season_mam).(monthname.(d))))
end

agg_seas_df = function(df)
    return(mean.(skipmissing.(eachcol(df))))
end

na_rm = function (df)
    return(collect(skipmissing(df)))
end

calc_exc_mda8 = function(df)
    return(ifelse.(df .< 120,0,1))
end

datapath = "/home/cschmidt/data/measmod_csv/"

data_files = readdir(datapath)
data_f = readdir(datapath, join=true)

csv_f = data_f[occursin.(".csv",data_f)]

biasmod_f = csv_f[occursin.("att_",csv_f)]

meas_f = csv_f[occursin.("meas_aut",csv_f)]

meta_f = csv_f[occursin.("meta",csv_f)]


#### Read in data in datafram
bias_camx = CSV.read(biasmod_f[2],DataFrame, missingstring = "NA")
bias_wrf = CSV.read(biasmod_f[4],DataFrame, missingstring = "NA")

mod_camx = CSV.read(biasmod_f[6],DataFrame, missingstring = "NA")
mod_wrf = CSV.read(biasmod_f[8],DataFrame, missingstring = "NA")

meas_aut = CSV.read(meas_f[2],DataFrame, missingstring = "NA")
meas_stat = meas_aut[:,2:end]
meta_meas = CSV.read(meta_f[1],DataFrame, missingstring = "NA")

##### We have to filter out columns from meta_meas and mod_xxx.
##### Only keep cols which are also in bias_xxx
biascol = names(bias_camx)
modcol =names(mod_wrf)
metacol= meta_meas[:,:station_european_code]

in(biascol).(modcol)
in(biascol).(metacol)

mod_camx = mod_camx[:,in(biascol).(modcol)]
mod_wrf = mod_wrf[:,in(biascol).(modcol)]

meta_meas = meta_meas[in(biascol).(metacol),:]

#### We have more NA's in model? files because some tiles are NA for extract
#sum.(ismissing.(eachcol(mod_camx))) |> plot

mod_col_nacount = sum.(eachcol(ismissing.(mod_camx)))

naind_model = findall(mod_col_nacount .< 10)

bias_camx = bias_camx[:,naind_model]
bias_wrf = bias_wrf[:,naind_model]
mod_camx = mod_camx[:,naind_model]
mod_wrf = mod_wrf[:,naind_model]
meas_stat = meas_stat[:,naind_model]
meta_meas = meta_meas[naind_model,:]

###### We also have to filter out station >1500 m
underalt = findall(meta_meas[:,:Hoehe] .< 1500)

###### save processed files
bias_camx = bias_camx[:,underalt]
bias_wrf = bias_wrf[:,underalt]
mod_camx = mod_camx[:,underalt]
mod_wrf = mod_wrf[:,underalt]
meas_stat = meas_stat[:,underalt]
meta_meas = meta_meas[underalt,:]

## trim model files because 1 timestep is 
mod_camx = mod_camx[1:end-1,:]
mod_wrf = mod_wrf[1:end-1,:]

##### Write out processed data_f
CSV.write("bias_camx.csv",bias_camx)
CSV.write("bias_wrf.csv",bias_wrf)
CSV.write("mod_camx.csv",mod_camx)
CSV.write("mod_wrf.csv",mod_wrf)
CSV.write("meas_stat.csv",meas_stat)
CSV.write("meta_meas.csv",meta_meas)




##### Create dates for data frames noleap na dleap for historical PARENT_GRID_RATIO
#####

cesm_date_range = DateTimeNoLeap(2007,1,1,) : Day(1) : DateTimeNoLeap(2016,12,31)
cesm_date = collect(cesm_date_range)
cesm_date = Dates_noleap(cesm_date)

meas_date = meas_aut[:,1]

s_jja(cesm_date)
s_mam(cesm_date)


using StatsPlots, Plots


#agg_seas_df(mod_camx)




density(na_rm(agg_seas_df(meas_stat)),label="Measurements")
density!(na_rm(agg_seas_df(mod_wrf)),label="WRF")
density!(na_rm(agg_seas_df(mod_camx)),label = "CMAx")

density(na_rm(agg_seas_df(meas_stat)),label="Measurements")
density!(na_rm(agg_seas_df(bias_wrf)),label="WRF")
density!(na_rm(agg_seas_df(bias_camx)),label = "CMAx")


######
######  Calcuate exceedances
######

mod_camx_ex = calc_exc_mda8(mod_camx)
mod_wrf_ex = calc_exc_mda8(mod_wrf)


disallowmissing!(bias_camx)

disallowmissing(bias_camx)
disallowmissing(bias_wrf)

ismissing.(bias_camx)


dissalo

bias_camx_ex = calc_exc_mda8(bias_camx)
bias_wrf_ex = calc_exc_mda8(bias_wrf)
mod_camx_ex = calc_exc_mda8(meas_aut)
mod_camx_ex = calc_exc_mda8(mod_camx)
mod_camx_ex = calc_exc_mda8(mod_camx)

DataFrames.disallowmissing(bias_camx)


ismissing.(bias_camx)


sum.(eachcol(ismissing.(bias_camx))) |> plot
sum.(eachcol(ismissing.(bias_wrf))) |> plot

###### Read in processed files

data_files = readdir(datapath)
data_f = readdir(datapath, join=true)

csv_f = data_f[occursin.(".csv",data_f)]

###### Wrie out processed files



bias_camx = CSV.read(csv_f[1],DataFrame)
bias_wrf = CSV.read(csv_f[2],DataFrame)
meas_aut = CSV.read(csv_f[3],DataFrame)
meta_aut = CSV.read(csv_f[4],DataFrame)
mod_camx = CSV.read(csv_f[5],DataFrame)
mod_wrf = CSV.read(csv_f[6],DataFrame)


