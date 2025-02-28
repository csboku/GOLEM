using CairoMakie,Statistics,NCDatasets,CFTime,ProgressMeter,CSV,DataFrames,Dates,JLD,Missings,Measures,DelimitedFiles,RollingFunctions,Colors,ColorSchemes

cd(@__DIR__)

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end



linec1 = RGB(68/255,119/255,170/255);
linec2 = RGB(102/255,204/255,238/255);
linec3 = RGB(34/255,136/255,51/255);
linec4 = RGB(204/255,187/255,68/255);
linec5 = RGB(238/255,102/255,119/255);
linec6 = RGB(170/255,51/255,119/255);
linec7 = RGB(187/255,187/255,187/255);




season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]
season_son = ["September","October","November"]
season_djf = ["December","January","February"]

linec = ["#4477AA", "#EE6677", "#228833", "#CCBB442", "#66CCEE", "#AA3377", "#BBBBBB"];
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

getvecnorm = function(df)
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

darken = function(color,n_shade)
    return(RGB(n_shade*color.r, n_shade*color.g, n_shade*color.b))
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



barplot_c = [:tomato2,:seagreen2,:tomato3,:seagreen3]


hist_years = meas_aut_exc_yagg[:,:year][1:end-1]

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


pap_c=["#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7"]

#### Bias correction validation Panel
dark23= ColorSchemes.Dark2_3
ColorSchemes.tol_bright
tol_m = ColorSchemes.tol_muted

dark232_linepattern = Makie.LinePattern(width=10, tilesize=(30,30), linecolor=:black, background_color=dark23[2]);
dark233_linepattern = Makie.LinePattern(width=10, tilesize=(30,30), linecolor=:black, background_color=dark23[3]);

p_bw=2

p4 = Figure(size=(800,600))

ax41 = Axis(p4[2,1:2],ylabel="Probability",xlabel="MDA8 O₃ [μg/m³]")
density!(getvecnorm(meas_aut[:,back_sub]),color = (:red, 0.0), strokecolor = dark23[1], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="Obs")
density!(getvecnorm(mod_wrf[:,back_sub]),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="WRFChem_S")
density!(getvecnorm(mod_camx[:,back_sub]),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="CAMx_S")
density!(na_rm(vec(wrf_grid_o3)),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="WRFChem⁺")
density!(na_rm(vec(camx_grid_o3)),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="CAMx⁺")
ylims!(0,0.025)

ax42 = Axis(p4[2,3:4],ylabel="Probability",xlabel="MDA8 O₃ [μg/m³]")
density!(getvecnorm(meas_aut[:,back_sub]),color = (:red, 0.0), strokecolor = dark23[1], strokewidth = 2,linestyle=:solid,bandwidth=p_bw)
density!(getvecnorm(bias_wrf[:,back_sub]),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:solid,bandwidth=p_bw)
density!(getvecnorm(bias_camx[:,back_sub]),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:solid,bandwidth=p_bw)
density!(na_rm(vec(wrf_bias_grid_o3)),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:dash,bandwidth=p_bw)
density!(na_rm(vec(camx_bias_grid_o3)),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:dash,bandwidth=p_bw)
ylims!(0,0.025)


ax43 = Axis(p4[4,1:3],
    ylabel="Exceedances",
    xticks = (1:5,["Obs","WRFChem","CAMx","WRFChem QMC","CAMx QMC"])
)
barplot!([mean_stat_exc(meas_aut_exc),mean_stat_exc(mod_wrf_exc),mean_stat_exc(mod_camx_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],color=[dark23[1],dark23[2],dark23[3],darken(dark23[2],0.7),darken(dark23[3],0.7)])


Legend(p4[1,:],
    [LineElement(color = dark23[1],strokewidth=2),LineElement(color = dark23[2],strokewidth=2),LineElement(color = dark23[3],strokewidth=2),LineElement(color = dark23[2],strokewidth=2,linestyle=:dash),LineElement(color = dark23[3],strokewidth=2,linestyle=:dash)],
    ["Obs","WRFChem_S","CAMx_S","WRFChem_D","CAMx_D"]
)


p4

save("/home/cschmidt/projects/attaino3/plots/panel/fig4_bias_validation_panel.svg",p4)


getvecnorm(meas_aut[:,back_sub])

meas_aut[:,back_sub]
mod_wrf[:,back_sub]


mean.(skipmissing.(eachcol(meas_aut)))
mean.(skipmissing.(eachcol(mod_wrf)))


##### Data Frames sortieren!!!!!!!
meas_aut[:,sortperm(names(meas_aut))]


fig_sc = Figure()

axsc1 = Axis(fig_sc[1,1])
ylims!(0,120)
xlims!(0,120)
scatter!(mean.(skipmissing.(eachcol(meas_aut[:,sortperm(names(meas_aut))][:,back_sub]))),mean.(skipmissing.(eachcol(meas_aut[:,sortperm(names(meas_aut))][:,back_sub]))))
scatter!(mean.(skipmissing.(eachcol(meas_aut[:,sortperm(names(meas_aut))][:,back_sub]))),mean.(skipmissing.(eachcol(bias_wrf[:,sortperm(names(meas_aut))][:,back_sub]))))
scatter!(mean.(skipmissing.(eachcol(meas_aut[:,sortperm(names(meas_aut))][:,back_sub]))),mean.(skipmissing.(eachcol(mod_wrf[:,sortperm(names(meas_aut))][:,back_sub]))),color=:green)
#scatter!(mean.(skipmissing.(eachcol(meas_aut[:,back_sub]))),mean.(skipmissing.(eachcol(bias_wrf[:,back_sub]))),color=:red)
#scatter!(mean.(skipmissing.(eachcol(meas_aut[:,back_sub]))),mean.(skipmissing.(eachcol(mod_camx[:,back_sub]))),color=:green)
#scatter!(mean.(skipmissing.(eachcol(meas_aut[:,back_sub]))),mean.(skipmissing.(eachcol(bias_camx[:,back_sub]))),color=:blue)


fig_sc

f5 = Figure()
Axis(f5[1,1])
lines!(mean.(skipmissing.(eachcol(meas_aut[:,back_sub]))))
lines!(mean.(skipmissing.(eachcol(mod_wrf[:,back_sub]))))
lines!(mean.(skipmissing.(eachcol(bias_wrf[:,back_sub]))))

f5

findall.(names(meas_aut),names(bias_wrf))

print(names(meas_aut[:,sortperm(names(meas_aut))]))
print(names(mod_wrf[:,sortperm(names(meas_aut))]))

sort(names(meas_aut))
sort(names(mod_wrf))

names(mod_wrf) |> print
names(meas_aut) |> print