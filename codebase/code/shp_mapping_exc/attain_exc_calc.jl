using NCDatasets, Dates, Statistics, Plots, StatsPlots, Colors, ColorSchemes, DataStructures, CFTime

cd(@__DIR__)

datapath_mda = "/home/cschmidt/data/attain/bias_corr_output_mda8/"

datapath_h = "/home/cschmidt/data/attain/bias_corr_output_hourly/"

#datapath_fin


att_files_mda8 = readdir(datapath_mda, join = false)
att_f_mda8 = readdir(datapath_mda, join = true)

att_files_h = readdir(datapath_h)[2:end]
att_f_h = readdir(datapath_h,join=true)[2:end]




att_file = Dataset(att_f_mda8[1])
att_datetime = att_file["time"][:]



path_mda8 = "/home/cschmidt/data/attain/bias_corr_output_mda8/"
files_mda8 = readdir(path_mda8)

ncin = Dataset(att_f_mda8[1])


ncin=Dataset(att_f_h[2])

ncin["time"]

#for f in files_mda8
for i in eachindex(att_f_mda8)
    println(files_mda8[i])
    att_file = Dataset(att_f_mda8[i])
    att_file_h = Dataset(att_f_h[i])
    att_datetime_h  = att_file_h["time"]
    datetime_h_tuple = CFTime.yearmonthday.(att_datetime_h)
    dates_h  = Date.(getindex.(datetime_h_tuple,1),getindex.(datetime_h_tuple,2),getindex.(datetime_h_tuple,3))
    dates_h_unique = unique(dates_h)
    #print(dates_h_unique)
    #if typeof(att_datetime) == wrong_type
    
    #att_datetime = collect(reinterpret(DateTime, att_datetime))
    #end
    #att_dates = Date.(att_datetime)

    att_o3 = att_file["O3"][:]


    att_o3[att_o3 .< 120] .= 0
    att_o3[att_o3 .> 120] .= 1

    att_o3[findall(ismissing, att_o3)] .= -99


    ds = NCDataset(files_mda8[i][1:end-3]*"_exc.nc","c")

    # Dimensions

    ds.dim["lon"] = 75
    ds.dim["lat"] = 26
    ds.dim["time"] = Inf

    # Declare variables

    nclon = defVar(ds,"lon", Float64, ("lon",), attrib = OrderedDict(
        "units"                     => "degrees",
        "long_name"                 => "longitude",
    ))

    nclat = defVar(ds,"lat", Float64, ("lat",), attrib = OrderedDict(
        "units"                     => "degrees",
        "long_name"                 => "latitude",
    ))

    nctime = defVar(ds,"time", Float64, ("time",), attrib = OrderedDict(
        "units"                     => "minutes since 2007-01-01 00:00:00",
        "long_name"                 => "time",
        "calendar"                  => "standard",
    ))

    ncO3 = defVar(ds,"O3", Float32, ("lon", "lat", "time"), attrib = OrderedDict(
        "units"                     => "ug/m3",
        "_FillValue"                => Float32(-1.0),
        "long_name"                 => "O3 bias corrected",
    ))

    # Define variables

    nclon[:] = att_file["lon"][:]
    nclat[:] = att_file["lat"][:]
    nctime[:] = Dates.value.(dates_h_unique)
    #print(Dates.value.(dates_h_unique))
    ncO3[:] = att_o3
    close(ds)
end


