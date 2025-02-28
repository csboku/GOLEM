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


inputdir = "/home/cschmidt/data/county_mapped"


input_files = readdir(inputdir,join=true)
input_f = readdir(inputdir,join=false)

input_files[1]

test_in = hist_mda8 = readdlm(input_files[12],',',skipstart=1)[:,:]


hist_mda8 = readdlm(input_files[1],',',skipstart=1)[:,3:end]
hist_mda8_exc = readdlm(input_files[2],',',skipstart=1)[:,3:end]

rcp45_nf_mda8 = readdlm(input_files[12],',',skipstart=1)[3:end,3:end]
rcp45_nf_mda8_exc = readdlm(input_files[13],',',skipstart=1)[3:end,3:end]

rcp85_nf_mda8 = readdlm(input_files[16],',',skipstart=1)[3:end,3:end]
rcp85_nf_mda8_exc = readdlm(input_files[17],',',skipstart=1)[3:end,3:end]

rcp45_ff_mda8 = readdlm(input_files[14],',',skipstart=1)[3:end,3:end]
rcp45_ff_mda8_exc = readdlm(input_files[15],',',skipstart=1)[3:end,3:end]

rcp85_ff_mda8 = readdlm(input_files[18],',',skipstart=1)[3:end,3:end]
rcp85_ff_mda8_exc = readdlm(input_files[19],',',skipstart=1)[3:end,3:end]



plot(tmean(rcp45_nf_mda8) - tmean(hist_mda8))


plot(cumsum(tsum(hist_mda8_exc)),c=linec2,lw=2,framestyle=:box,label="Hist",yformatter=:plain)
plot!(cumsum(tsum(rcp45_nf_mda8_exc)),c=linec4,lw=2,label="RCP45_NF")
plot!(cumsum(tsum(rcp45_ff_mda8_exc)),c=linec4,linestyle=:dash,lw=2,label="RCP45_FF")
plot!(cumsum(tsum(rcp85_nf_mda8_exc)),c=linec6,lw=2,label="RCP85_NF")
plot!(cumsum(tsum(rcp85_ff_mda8_exc)),c=linec6,lw=2,linestyle=:dash,label="RCP85_FF")
ylabel!("Exceedances for all Municipalities")
xticks!([0,730,1460,2190,2920],["0","2","4","6","8"])
xlabel!("Year")
png("tseries_scenarios.png")


qqplot(tmean(hist_mda8),tmean(rcp45_nf_mda8),markershape=:cross,c=linec4,label="RCP45 NF",framestyle=:box)
qqplot!(tmean(hist_mda8),tmean(rcp85_nf_mda8),markershape=:cross,c=linec6, label="RCP8.5 NF")
title!("NF")
png("qq_nf")

qqplot(tmean(hist_mda8),tmean(rcp45_ff_mda8),markershape=:cross,c=linec4,label="RCP45 NF",framestyle=:box)
qqplot!(tmean(hist_mda8),tmean(rcp85_ff_mda8),markershape=:cross,c=linec6, label="RCP8.5 NF")
title!("FF")
png("qq_ff")




#########Boxplots
boxplot(spmean(hist_mda8),framestyle=:box,legend=false,c=linec2)
boxplot!(spmean(rcp45_nf_mda8),c=linec4)
boxplot!(spmean(rcp85_nf_mda8),c=linec6)
boxplot!(spmean(rcp45_ff_mda8),c=linec4)
boxplot!(spmean(rcp85_ff_mda8),c=linec6)
ylims!(40,140)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("O₃ mda8 [μg/m³]")
png("box_dist_all")

boxplot(spmean(hist_mda8[mam_cesm_sub,:]),framestyle=:box,legend=false,c=linec2)
boxplot!(spmean(rcp45_nf_mda8[mam_cesm_sub,:]),c=linec4)
boxplot!(spmean(rcp85_nf_mda8[mam_cesm_sub,:]),c=linec6)
boxplot!(spmean(rcp45_ff_mda8[mam_cesm_sub,:]),c=linec4)
boxplot!(spmean(rcp85_ff_mda8[mam_cesm_sub,:]),c=linec6)
ylims!(40,140)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("O₃ mda8 [μg/m³]")
title!("MAM")
png("box_dist_mam")

boxplot(spmean(hist_mda8[jja_cesm_sub,:]),framestyle=:box,legend=false,c=linec2)
boxplot!(spmean(rcp45_nf_mda8[jja_cesm_sub,:]),c=linec4)
boxplot!(spmean(rcp85_nf_mda8[jja_cesm_sub,:]),c=linec6)
boxplot!(spmean(rcp45_ff_mda8[jja_cesm_sub,:]),c=linec4)
boxplot!(spmean(rcp85_ff_mda8[jja_cesm_sub,:]),c=linec6)
ylims!(40,140)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("O₃ mda8 [μg/m³]")
title!("MAM")
png("box_dist_jja")



boxplot(spsum(hist_mda8_exc)/10,framestyle=:box,legend=false,outliers=false,c=linec2)
boxplot!(spsum(rcp45_nf_mda8_exc)/10,c=linec4,outliers=false)
boxplot!(spsum(rcp85_nf_mda8_exc)/10,c=linec6,outliers=false)
boxplot!(spsum(rcp45_ff_mda8_exc)/10,c=linec4,outliers=false)
boxplot!(spsum(rcp85_ff_mda8_exc)/10,c=linec6,outliers=false)
ylims!(0,60)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
png("box_dist_all_exc")


boxplot(spsum(hist_mda8_exc[mam_cesm_sub,:])/10,framestyle=:box,legend=false,outliers=false,c=linec2)
boxplot!(spsum(rcp45_nf_mda8_exc[mam_cesm_sub,:])/10,c=linec4,outliers=false)
boxplot!(spsum(rcp85_nf_mda8_exc[mam_cesm_sub,:])/10,c=linec6,outliers=false)
boxplot!(spsum(rcp45_ff_mda8_exc[mam_cesm_sub,:])/10,c=linec4,outliers=false)
boxplot!(spsum(rcp85_ff_mda8_exc[mam_cesm_sub,:])/10,c=linec6,outliers=false)
ylims!(0,40)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
title!("MAM")
png("box_dist_mam_exc")

boxplot(spsum(hist_mda8_exc[jja_cesm_sub,:])/10,framestyle=:box,legend=false,outliers=false,c=linec2)
boxplot!(spsum(rcp45_nf_mda8_exc[jja_cesm_sub,:])/10,c=linec4,outliers=false)
boxplot!(spsum(rcp85_nf_mda8_exc[jja_cesm_sub,:])/10,c=linec6,outliers=false)
boxplot!(spsum(rcp45_ff_mda8_exc[jja_cesm_sub,:])/10,c=linec4,outliers=false)
boxplot!(spsum(rcp85_ff_mda8_exc[jja_cesm_sub,:])/10,c=linec6,outliers=false)
ylims!(0,40)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
title!("JJA")
png("box_dist_jja_exc")


###### Demsities
density(spmean(hist_mda8),framestyle=:box,c=linec2,label="Hist",lw=3)
density!(spmean(rcp45_nf_mda8),c=linec4,label="RCP45_NF",lw=2)
density!(spmean(rcp85_nf_mda8),c=linec6,label="RCP85_NF",lw=2)
density!(spmean(rcp45_ff_mda8),c=linec4,linestyle=:dash,label="RCP45_FF",lw=2)
density!(spmean(rcp85_ff_mda8),c=linec6,linestyle=:dash,label="RCP85_FF",lw=2)
xlabel!("O₃ mda8 [μg/m³]")
ylabel!("Probability")
ylims!(0,0.1)
png("dens_dist_all")

density(spmean(hist_mda8[mam_cesm_sub,:]),framestyle=:box,c=linec2,label="Hist",lw=3)
density!(spmean(rcp45_nf_mda8[mam_cesm_sub,:]),c=linec4,label="RCP45_NF",lw=2)
density!(spmean(rcp85_nf_mda8[mam_cesm_sub,:]),c=linec6,label="RCP85_NF",lw=2)
density!(spmean(rcp45_ff_mda8[mam_cesm_sub,:]),c=linec4,linestyle=:dash,label="RCP45_FF",lw=2)
density!(spmean(rcp85_ff_mda8[mam_cesm_sub,:]),c=linec6,linestyle=:dash,label="RCP85_FF",lw=2)
xlabel!("O₃ mda8 [μg/m³]")
ylabel!("Probability")
ylims!(0,0.1)
title!("MAM")
png("dens_dist_mam")

density(spmean(hist_mda8[jja_cesm_sub,:]),framestyle=:box,c=linec2,label="Hist",lw=3)
density!(spmean(rcp45_nf_mda8[jja_cesm_sub,:]),c=linec4,label="RCP45_NF",lw=2)
density!(spmean(rcp85_nf_mda8[jja_cesm_sub,:]),c=linec6,label="RCP85_NF",lw=2)
density!(spmean(rcp45_ff_mda8[jja_cesm_sub,:]),c=linec4,linestyle=:dash,label="RCP45_FF",lw=2)
density!(spmean(rcp85_ff_mda8[jja_cesm_sub,:]),c=linec6,linestyle=:dash,label="RCP85_FF",lw=2)
xlabel!("O₃ mda8 [μg/m³]")
ylabel!("Probability")
ylims!(0,0.1)
title!("JJA")
png("dens_dist_jja")




density(spsum(hist_mda8_exc)/10,framestyle=:box,c=linec2,label="Hist",lw=3)
density!(spsum(rcp45_nf_mda8_exc)/10,c=linec4,label="RCP45_NF",lw=2)
density!(spsum(rcp85_nf_mda8_exc)/10,c=linec6,label="RCP85_NF",lw=2)
density!(spsum(rcp45_ff_mda8_exc)/10,c=linec4,linestyle=:dash,label="RCP45_FF",lw=2)
density!(spsum(rcp85_ff_mda8_exc)/10,c=linec6,linestyle=:dash,label="RCP85_FF",lw=2)
xlabel!("Exceedances")
ylabel!("Probability")
ylims!(0,0.2)
png("dens_dist_all_exc")

density(spsum(hist_mda8_exc[mam_cesm_sub,:])/10,framestyle=:box,c=linec2,label="Hist",lw=3)
density!(spsum(rcp45_nf_mda8_exc[mam_cesm_sub,:])/10,c=linec4,label="RCP45_NF",lw=2)
density!(spsum(rcp85_nf_mda8_exc[mam_cesm_sub,:])/10,c=linec6,label="RCP85_NF",lw=2)
density!(spsum(rcp45_ff_mda8_exc[mam_cesm_sub,:])/10,c=linec4,linestyle=:dash,label="RCP45_FF",lw=2)
density!(spsum(rcp85_ff_mda8_exc[mam_cesm_sub,:])/10,c=linec6,linestyle=:dash,label="RCP85_FF",lw=2)
xlabel!("Exceedances")
ylabel!("Probability")
ylims!(0,0.2)
title!("MAM")
png("dens_dist_mam_exc")

density(spsum(hist_mda8_exc[jja_cesm_sub,:])/10,framestyle=:box,c=linec2,label="Hist",lw=3)
density!(spsum(rcp45_nf_mda8_exc[jja_cesm_sub,:])/10,c=linec4,label="RCP45_NF",lw=2)
density!(spsum(rcp85_nf_mda8_exc[jja_cesm_sub,:])/10,c=linec6,label="RCP85_NF",lw=2)
density!(spsum(rcp45_ff_mda8_exc[jja_cesm_sub,:])/10,c=linec4,linestyle=:dash,label="RCP45_FF",lw=2)
density!(spsum(rcp85_ff_mda8_exc[jja_cesm_sub,:])/10,c=linec6,linestyle=:dash,label="RCP85_FF",lw=2)
xlabel!("Exceedances")
ylabel!("Probability")
ylims!(0,0.2)
title!("JJA")
png("dens_dist_jja_exc")


######## Barplots exc

mean(spsum(hist_mda8_exc))/10

all_exc = vcat(mean(spsum(hist_mda8_exc))/10,mean(spsum(rcp45_nf_mda8_exc))/10,mean(spsum(rcp85_nf_mda8_exc))/10,mean(spsum(rcp45_ff_mda8_exc))/10,mean(spsum(rcp85_ff_mda8_exc))/10)
mam_exc = vcat(mean(spsum(hist_mda8_exc[mam_cesm_sub,:]))/10,mean(spsum(rcp45_nf_mda8_exc[mam_cesm_sub,:]))/10,mean(spsum(rcp85_nf_mda8_exc[mam_cesm_sub,:]))/10,mean(spsum(rcp45_ff_mda8_exc[mam_cesm_sub,:]))/10,mean(spsum(rcp85_ff_mda8_exc[mam_cesm_sub,:]))/10)
jja_exc = vcat(mean(spsum(hist_mda8_exc[jja_cesm_sub,:]))/10,mean(spsum(rcp45_nf_mda8_exc[jja_cesm_sub,:]))/10,mean(spsum(rcp85_nf_mda8_exc[jja_cesm_sub,:]))/10,mean(spsum(rcp45_ff_mda8_exc[jja_cesm_sub,:]))/10,mean(spsum(rcp85_ff_mda8_exc[jja_cesm_sub,:]))/10)
son_exc = vcat(mean(spsum(hist_mda8_exc[son_cesm_sub,:]))/10,mean(spsum(rcp45_nf_mda8_exc[son_cesm_sub,:]))/10,mean(spsum(rcp85_nf_mda8_exc[son_cesm_sub,:]))/10,mean(spsum(rcp45_ff_mda8_exc[son_cesm_sub,:]))/10,mean(spsum(rcp85_ff_mda8_exc[son_cesm_sub,:]))/10)
djf_exc = vcat(mean(spsum(hist_mda8_exc[djf_cesm_sub,:]))/10,mean(spsum(rcp45_nf_mda8_exc[djf_cesm_sub,:]))/10,mean(spsum(rcp85_nf_mda8_exc[djf_cesm_sub,:]))/10,mean(spsum(rcp45_ff_mda8_exc[djf_cesm_sub,:]))/10,mean(spsum(rcp85_ff_mda8_exc[djf_cesm_sub,:]))/10)

all_exc_table = hcat(mam_exc,jja_exc,son_exc,djf_exc)

groupedbar(all_exc_table)


bar(all_exc,c=[linec2,linec4,linec6,linec4,linec6],framestyle=:box,legend=false)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
ylims!(0,30)
png("barexc_all")

bar(mam_exc,c=[linec2,linec4,linec6,linec4,linec6],framestyle=:box,legend=false)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
ylims!(0,15)
title!("MAM")
png("barexc_mam")

bar(jja_exc,c=[linec2,linec4,linec6,linec4,linec6],framestyle=:box,legend=false)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
title!("JJA")
ylims!(0,20)
png("barexc_jja")

bar(son_exc,c=[linec2,linec4,linec6,linec4,linec6],framestyle=:box,legend=false)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
title!("SON")
ylims!(0,20)
png("barexc_son")

bar(djf_exc,c=[linec2,linec4,linec6,linec4,linec6],framestyle=:box,legend=false)
xticks!([1,2,3,4,5],["HIST","RCP45_NF","RCP85_NF","RCP_45_FF","RCP85_FF"])
ylabel!("Exceedances")
title!("DJF")
ylims!(0,20)
png("barexc_djf")
