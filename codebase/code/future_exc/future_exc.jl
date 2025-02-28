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

datapath = "/home/cschmidt/data/attain_future_csv/exc"

modelstrings = ["Historic","NF_RCP4.5", "NF_RCP8.5","FF_RCP4.5","FF_RCP8.5"]



data_files = readdir(datapath)
data_f = readdir(datapath, join=true)

csv_f = data_f[occursin.(".csv",data_f)]

att_dates = load("meas_dates.jld")
att_dates_cesm = att_dates["cesm_dates"]
att_dates_meas = att_dates["meas_dates"]

####### Subset indices per season_djf

mam_s_cesm = findall(Month.(att_dates_cesm) == season_mam)

mam_cesm_sub = in(season_mam).(monthname.(att_dates_cesm))
jja_cesm_sub = in(season_jja).(monthname.(att_dates_cesm))
son_cesm_sub = in(season_son).(monthname.(att_dates_cesm)) 
djf_cesm_sub = in(season_djf).(monthname.(att_dates_cesm))

csv_f[5]

hist_wrf = CSV.read(csv_f[1],DataFrame)
rcp45_ff = CSV.read(csv_f[2],DataFrame)
rcp45_nf = CSV.read(csv_f[3],DataFrame)
rcp85_ff = CSV.read(csv_f[4],DataFrame)
rcp85_nf = CSV.read(csv_f[5],DataFrame)

hist_wrf = readdlm(csv_f[1],',',skipstart=1)
rcp45_ff = readdlm(csv_f[2],',',skipstart=1)
rcp45_nf = readdlm(csv_f[3],',',skipstart=1)
rcp85_ff = readdlm(csv_f[4],',',skipstart=1)
rcp85_nf = readdlm(csv_f[5],',',skipstart=1)



mean(sum(hist_wrf,dims=1)/10)
mean(sum(rcp45_ff,dims=1)/10)
mean(sum(rcp45_nf,dims=1)/10)
mean(sum(rcp85_ff,dims=1)/10)
mean(sum(rcp85_nf,dims=1)/10)


sum(hist_wrf)
sum(rcp45_ff)
sum(rcp45_nf)
sum(rcp85_ff)
sum(rcp85_nf)

exc_all = vcat(mean(sum(hist_wrf,dims=1)/10),mean(sum(rcp45_nf,dims=1)/10),mean(sum(rcp85_nf,dims=1)/10),mean(sum(rcp45_ff,dims=1)/10),mean(sum(rcp85_ff,dims=1)/10))

exc_mam = vcat(mean(sum(hist_wrf[mam_cesm_sub,:],dims=1)/10),mean(sum(rcp45_nf[mam_cesm_sub,:],dims=1)/10),mean(sum(rcp85_nf[mam_cesm_sub,:],dims=1)/10),mean(sum(rcp45_ff[mam_cesm_sub,:],dims=1)/10),mean(sum(rcp85_ff[mam_cesm_sub,:],dims=1)/10))
exc_jja = vcat(mean(sum(hist_wrf[jja_cesm_sub,:],dims=1)/10),mean(sum(rcp45_nf[jja_cesm_sub,:],dims=1)/10),mean(sum(rcp85_nf[jja_cesm_sub,:],dims=1)/10),mean(sum(rcp45_ff[jja_cesm_sub,:],dims=1)/10),mean(sum(rcp85_ff[jja_cesm_sub,:],dims=1)/10))

bar(exc_all, c = [linec2,linec4,linec6,linec4,linec6],legend=false,framestyle=:box)
xticks!(1:5,modelstrings)
ylabel!("Exceedances")
ylims!(0,35)
png("barfuture_all.png")
bar(exc_mam, c = [linec2,linec4,linec6,linec4,linec6],legend = false,framestyle=:box)
xticks!(1:5,modelstrings)
ylims!(0,20)
ylabel!("Exceedances")
title!("MAM")
png("barfuture_mam.png")
bar(exc_jja,c = [linec2,linec4,linec6,linec4,linec6],legend=false,framestyle=:box)
xticks!(1:5,modelstrings)
ylims!(0,20)
ylabel!("Exceedances")
title!("JJA")
png("barfuture_jja.png")


bar(exc_all, c = ["darkseagreen","#709fcc","#980002","#709fcc","#980002"],legend=false)
xticks!(1:5,modelstrings)
ylabel!("Exceedances")
title!("Exceedances, All Year")
ylims!(0,35)
png("barfuture_all.png")
bar(exc_mam, c = ["darkseagreen","#709fcc","#980002","#709fcc","#980002"],legend = false)
xticks!(1:5,modelstrings)
ylims!(0,20)
ylabel!("Exceedances")
title!("Exceedances, MAM")
png("barfuture_mam.png")
bar(exc_jja, c = ["darkseagreen","#709fcc","#980002","#709fcc","#980002"],legend=false)
xticks!(1:5,modelstrings)
ylims!(0,20)
ylabel!("Exceedances")
title!("Exceedances, JJA")
png("barfuture_jja.png")






