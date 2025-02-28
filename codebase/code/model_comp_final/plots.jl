using CairoMakie,DelimitedFiles,NCDatasets,Statistics,JLD,Missings,CSV,DataFrames,Colors,ColorSchemes,NCDatasets,CFTime,Dates

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


meas_aut = readdlm("data/meas/attain_meas_mda8_bcstations.csv",',',skipstart=1)
meas_date = meas_aut[:,1]
meas_aut = meas_aut[:,2:end]

meas_date = Date.(meas_date)
##Load date jld

att_dates = load("meas_dates.jld")
att_dates_cesm = att_dates["cesm_dates"]
att_dates_meas = att_dates["meas_dates"]

####Filter out leap days from measuremnts
leap_index = Dates.month.(meas_date) .== 2 .&& Dates.day.(meas_date) .== 29 
findall(leap_index .== 1)

meas_aut = meas_aut[Not(leap_index .== 1 ),:]

bias_wrf = readdlm("data/biascorr/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]
bias_camx = readdlm("data/biascorr/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]


mod_wrf = readdlm("data/model/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_bcstations.csv",',',skipstart=1)[:,2:end]

mod_camx = readdlm("data/model/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_bcstations.csv",',',skipstart=1)[:,2:end]


bias_wrf[bias_wrf .== "NA"] .= missing
bias_camx[bias_camx .== "NA"] .= missing
meas_aut[meas_aut .== "NA"] .= missing

bias_camx = convert(Matrix{Union{Missing, Float64}}, bias_camx)
bias_wrf = convert(Matrix{Union{Missing, Float64}}, bias_wrf)
mod_wrf = convert(Matrix{Union{Missing, Float64}}, mod_wrf)[2:end,:]
mod_camx = convert(Matrix{Union{Missing, Float64}}, mod_camx)[2:end,:]

mod_wrf

#mod_wrf[mod_wrf .== "NA"] .= missing
#mod_camx[mod_camx .== "NA"] .= missing


bias_wrf_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), bias_wrf.> 120)
bias_camx_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), bias_camx .> 120)
mod_wrf_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), mod_wrf.> 120)
mod_camx_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), mod_camx.> 120)
meas_aut_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), meas_aut.> 120)

meas_aut[:,1]


####### Subset indices per season_djf

meas_aut








###### Create dates for CESM
#cesm_date_range = DateTimeNoLeap(2007,1,1,) : Day(1) : DateTimeNoLeap(2016,12,31)
#cesm_dates = collect(cesm_date_range)
#cesm_dates = Dates_noleap(cesm_date)

###### Load dates from source file 
#meas_raw = CSV.read("/home/cschmidt/data/measmod_csv/vault/meas_aut_o3_mda8_nafix.csv",DataFrame)
#meas_dates = meas_raw[:,:date]
#@save "meas_dates.jld" meas_dates cesm_dates



mam_s_cesm = findall(Month.(att_dates_cesm) == season_mam)

mam_cesm_sub = in(season_mam).(monthname.(att_dates_cesm))
jja_cesm_sub = in(season_jja).(monthname.(att_dates_cesm))
son_cesm_sub = in(season_son).(monthname.(att_dates_cesm)) 
djf_cesm_sub = in(season_djf).(monthname.(att_dates_cesm))

mam_meas_sub = in(season_mam).(monthname.(att_dates_meas))
jja_meas_sub = in(season_jja).(monthname.(att_dates_meas))
son_meas_sub = in(season_son).(monthname.(att_dates_meas)) 
djf_meas_sub = in(season_djf).(monthname.(att_dates_meas))




wrf_grid = Dataset("/gpfs/data/fs71391/cschmidt/lenian/data/attain/model_output/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_cropped.nc")
wrf_grid_o3 = wrf_grid["O3"]
camx_grid = Dataset("/gpfs/data/fs71391/cschmidt/lenian/data/attain/model_output/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda_cropped.nc")
camx_grid_o3 = camx_grid["O3"]

wrf_bias_grid = Dataset("/gpfs/data/fs71391/cschmidt/lenian/data/attain/bias_corr_output_mda8/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
wrf_bias_grid_o3 = wrf_bias_grid["O3"]

camx_bias_grid = Dataset("/gpfs/data/fs71391/cschmidt/lenian/data/attain/bias_corr_output_mda8/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
camx_bias_grid_o3 = camx_bias_grid["O3"]


pap_c=["#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7"]

#### Bias correction validation Panel
dark23= ColorSchemes.Dark2_3
ColorSchemes.tol_bright
tol_m = ColorSchemes.tol_muted

dark232_linepattern = Makie.LinePattern(width=10, tilesize=(30,30), linecolor=:black, background_color=dark23[2]);
dark233_linepattern = Makie.LinePattern(width=10, tilesize=(30,30), linecolor=:black, background_color=dark23[3]);

meas_missing = (!ismissing).(meas_aut)

mod_wrf[meas_missing]
bias_wrf[meas_missing]

qqplot(meas_aut[meas_missing],mod_wrf[meas_missing],color=(dark23[2],0.5),qqline=:identity)

p_bw=2

p4 = Figure(size=(1200,800))

Legend(p4[1,1:3],
    orientation=:horizontal,
    [LineElement(color = dark23[1],strokewidth=2),LineElement(color = dark23[2],strokewidth=2),LineElement(color = dark23[3],strokewidth=2),LineElement(color = dark23[2],strokewidth=2,linestyle=:dash),LineElement(color = dark23[3],strokewidth=2,linestyle=:dash)],
    ["Obs","WRFChem_S","CAMx_S","WRFChem_D","CAMx_D"]
)


ax41 = Axis(p4[2,1],ylabel="Probability",xlabel="MDA8 O₃ [μg/m³]")
density!(getvecnorm(meas_aut),color = (:red, 0.0), strokecolor = dark23[1], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="Obs")
density!(getvecnorm(mod_wrf),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="WRFChem_S")
density!(getvecnorm(mod_camx),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="CAMx_S")
density!(na_rm(vec(wrf_grid_o3)),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="WRFChem⁺")
density!(na_rm(vec(camx_grid_o3)),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="CAMx⁺")
ylims!(0,0.025)


ax42 = Axis(p4[2,2],ylabel="MDA8 O₃ [μg/m³]",xlabel="MDA8 O₃ [μg/m³]")
qqplot!(meas_aut[meas_missing],mod_wrf[meas_missing],color=(dark23[2],0.5),qqline=:identity)
qqplot!(meas_aut[meas_missing],mod_camx[meas_missing],color=(dark23[3],0.5),qqline=:identity)
ylims!(0,250)
xlims!(0,250)

ax43 = Axis(p4[2,3],
    ylabel="Exceedances",
    xticks = (1:3,["Obs","WRFChem","CAMx"])
)
barplot!([mean_stat_exc(meas_aut_exc),mean_stat_exc(mod_wrf_exc),mean_stat_exc(mod_camx_exc)],color=[dark23[1],dark23[2],dark23[3]])


ax44 = Axis(p4[3,1],ylabel="Probability",xlabel="MDA8 O₃ [μg/m³]")
density!(getvecnorm(meas_aut),color = (:red, 0.0), strokecolor = dark23[1], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="Obs")
density!(getvecnorm(bias_wrf),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="WRFChem_S")
density!(getvecnorm(bias_camx),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="CAMx_S")
density!(na_rm(vec(wrf_bias_grid_o3)),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="WRFChem⁺")
density!(na_rm(vec(camx_bias_grid_o3)),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="CAMx⁺")
ylims!(0,0.025)


ax45 = Axis(p4[3,2],ylabel="MDA8 O₃ [μg/m³]",xlabel="MDA8 O₃ [μg/m³]")
qqplot!(meas_aut[meas_missing],bias_wrf[meas_missing],color=(dark23[2],0.5),qqline=:identity)
qqplot!(meas_aut[meas_missing],bias_camx[meas_missing],color=(dark23[3],0.5),qqline=:identity)
ylims!(0,250)
xlims!(0,250)

ax46 = Axis(p4[3,3],
    ylabel="Exceedances",
    xticks = (1:3,["Obs","WRFChem QMC","CAMx QMC"])
)
barplot!([mean_stat_exc(meas_aut_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],color=[dark23[1],dark23[2],dark23[3]])




p4
save("fig4_bias_validation_new.svg",p4)





ax43 = Axis(p4[4,1:3],
    ylabel="Exceedances",
    xticks = (1:5,["Obs","WRFChem QMC","CAMx QMC"])
)
barplot!([mean_stat_exc(meas_aut_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],color=[dark23[1],dark23[2],dark23[3]])


Legend(p4[1,:],
    orientation=:horizontal,
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