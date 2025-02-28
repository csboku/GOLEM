using NCDatasets, Plots, Dates, Statistics, StatsPlots, ColorSchemes, CFTime, CSV, DataFrames

#cd(@__DIR__)


spmean = function(ds,var,idx)
    if idx == "all"
        ds_spmean = mapslices(x->mean(skipmissing(x)),ds[var][:,:,:],dims = [1,2])[:]
    else
        ds_spmean = mapslices(x->mean(skipmissing(x)),ds[var][:,:,idx],dims = [1,2])[:]
    end
    return transpose(ds_spmean)
end

tmean = function(ds,var,idx)
    if idx == "all"
        ds_tmean = mapslices(x->mean(skipmissing(x)),ds[var][:,:,:],dims = [3])[:,:,1]
    else
        ds_tmean = mapslices(x->mean(skipmissing(x)),ds[var][:,:,idx],dims = [3])[:,:,1]
    end
    return transpose(ds_tmean)
end

spsum = function(ds,var,idx)
    if idx == "all"
        ds_spmean = mapslices(x->sum(skipmissing(x)),ds[var][:,:,:],dims = [1,2])[:]
    else
        ds_spmean = mapslices(x->sum(skipmissing(x)),ds[var][:,:,idx],dims = [1,2])[:]
    end
    ds_spmean_format = replace(ds_spmean, 0 => missing)
    return transpose(ds_spmean_format)
end

tsum = function(ds,var,idx)
    if idx == "all"
        ds_tmean = mapslices(x->sum(skipmissing(x)),ds[var][:,:,:],dims = [3])[:,:,1]
    else
        ds_tmean = mapslices(x->sum(skipmissing(x)),ds[var][:,:,idx],dims = [3])[:,:,1]
    end
    ds_tmean_format = replace(ds_tmean, 0 => missing)
    return transpose(ds_tmean_format)
end

tdiff_mean = function(ds1,ds2,var,idx)
    if idx == "all"
        out = mapslices(x->mean(skipmissing(x)),ds1[var][:,:,:],dims = [3])[:,:,1] - mapslices(x->mean(skipmissing(x)),ds2[var][:,:,:],dims = [3])[:,:,1]
    else
        out = mapslices(x->mean(skipmissing(x)),ds1[var][:,:,idx],dims = [3])[:,:,1] - mapslices(x->mean(skipmissing(x)),ds2[var][:,:,idx],dims = [3])[:,:,1]
    end
    return transpose(out)
end

tdiff_sum = function(ds1,ds2,var,idx)
    if idx == "all"
        out = mapslices(x->sum(skipmissing(x)),ds1[var][:,:,:],dims = [3])[:,:,1] - mapslices(x->sum(skipmissing(x)),ds2[var][:,:,:],dims = [3])[:,:,1]
    else
        out = mapslices(x->sum(skipmissing(x)),ds1[var][:,:,idx],dims = [3])[:,:,1] - mapslices(x->sum(skipmissing(x)),ds2[var][:,:,idx],dims = [3])[:,:,1]
    end
    out_format = replace(out, 0 => missing)
    return transpose(out_format)
end

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end

na_rm = function(vec)
    return collect(skipmissing(vec))
end

## Create arrays with desired dates_ff manually according to hourly files
dr = Date(2014,1,29):Day(1):Date(2014,2,3)

dt_hist_noleap = DateTimeNoLeap(2007,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2016,12,31,23,00,00)
dt_hist_noleap = collect(dt_hist_noleap)
dt_hist_leap = DateTime(2007,01,01,00,00,00): Hour(1) : DateTime(2016,12,31,23,00,00)
dt_hist_leap = collect(dt_hist_leap)
dt_rcp26_noleap = DateTimeNoLeap(2007,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2017,01,03,23,00,00)
dt_rcp26_noleap = collect(dt_rcp26_noleap)
dt_nf_noleap = DateTimeNoLeap(2026,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2035,12,31,23,00,00)
dt_nf_noleap = collect(dt_nf_noleap)
dt_ff_noleap = DateTimeNoLeap(2046,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2055,12,31,23,00,00)
dt_ff_noleap = collect(dt_nf_noleap)

dt_attain = vcat([dt_hist_leap],[dt_hist_leap],[dt_rcp26_noleap],[dt_nf_noleap],[dt_ff_noleap],[dt_nf_noleap],[dt_ff_noleap])

####
#### Datapaths and filestrings
####

#datadir = "/home/cschmidt/data/attain/output_bias_correction"
datadir = "/home/cschmidt/data/attain/output_bias_correction"
plots_outdir = "plots/original_alt/"


exc_files = readdir(datadir*"/bias_exc/", join=true)
hourly_files = readdir(datadir*"/hourly/", join=true)
mda8_files = readdir(datadir*"/mda8/", join=true)

modelstrings = ["hist_wrf","hist_camx","hist_rcp26","NF_RCP4.5", "FF_RCP4.5","NF_RCP8.5","FF_RCP8.5"]
seasons_strings = ["all","DJF","MAM","JJA","SON"]


########
######## Get dimension and date info for datasets
########

hourly_ds_hist = Dataset(hourly_files[1])


lat = hourly_ds_hist["lat"][:]
lon = hourly_ds_hist["lon"][:]


close(hourly_ds_hist)

datetime_hist = dt_hist_leap
dates_hist = unique(Date.(datetime_hist))
months_hist = monthname.(dates_hist)


datetime_rcp26 = dt_rcp26_noleap
datetime_rcp26 = yearmonthday.(datetime_rcp26)
dates_rcp26 = unique(Date.(getindex.(datetime_rcp26,1),getindex.(datetime_rcp26,2),getindex.(datetime_rcp26,3)))
months_rcp26 = monthname.(dates_rcp26)


datetime_nf = dt_nf_noleap
dates_nf = unique(Dates_noleap(datetime_nf))
months_nf = monthname.(dates_nf)

datetime_ff = dt_ff_noleap
dates_ff = unique(Dates_noleap(datetime_ff))
months_ff = monthname.(dates_ff)

season_djf = ["December", "January", "February"]
season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]
season_son = ["September", "October", "November"]

seasons_attain = vcat([season_djf],[season_mam],[season_jja],[season_son])
dates_attain = vcat([dates_hist],[dates_hist],[dates_rcp26],[dates_nf],[dates_nf],[dates_ff],[dates_ff])

season_subsets_datetime = []
for i in 1:length(dt_attain)
    outsub = []
    for j in 1:length(seasons_attain)
        msub = findall(in(seasons_attain[j]).(monthname.(dt_attain[i])))
        outsub = vcat(outsub,[msub])
    end
    global season_subsets_datetime  = vcat(season_subsets_datetime,[outsub])
end


##### Get month month subsets
month_str = unique(monthname.(dt_attain[1]))


month_subsets_datetime = []
for i in 1:length(dt_attain)
    outsub = []
    for j in 1:length(month_str)
        msub = findall(month_str[j] .== monthname.(dt_attain[i]))
        outsub = vcat(outsub,[msub])
    end
    global month_subsets_datetime  = vcat(month_subsets_datetime,[outsub])
end

season_subsets_date = []
for i in 1:length(dt_attain)
    outsub = []
    for j in 1:length(seasons_attain)
        msub = findall(in(seasons_attain[j]).(monthname.(dates_attain[i])))
        outsub = vcat(outsub,[msub])
    end
    global season_subsets_date  = vcat(season_subsets_date,[outsub])
end


##### Get month month subsets
month_str = unique(monthname.(dt_attain[1]))


month_subsets_date = []
for i in 1:length(dt_attain)
    outsub = []
    for j in 1:length(month_str)
        msub = findall(month_str[j] .== monthname.(dates_attain[i]))
        outsub = vcat(outsub,[msub])
    end
    global month_subsets_date  = vcat(month_subsets_date,[outsub])
end
