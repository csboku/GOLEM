module GOLEM

using NCDatasets, Plots, Dates, Statistics, StatsPlots, ColorSchemes, CFTime, CSV, DataFrames, OrderedCollections

# Re-export commonly used packages
export NCDatasets, Plots, Dates, Statistics, StatsPlots, ColorSchemes, CFTime, CSV, DataFrames

#####################################
# Data Processing Module
#####################################
module DataProcessing

using NCDatasets, Dates, Statistics, DataFrames, CFTime

export spmean, tmean, spsum, tsum, tdiff_mean, tdiff_sum, 
       na_rm, Dates_noleap, calc_exc_mda8,
       get_date_ranges, create_season_subsets, getvec,
       read_nc_data, read_csv_data, filter_cols_by_value

"""
    spmean(ds, var, idx)

Calculate spatial mean across dimensions 1 and 2 of NetCDF data.
"""
function spmean(ds, var, idx)
    if idx == "all"
        ds_spmean = mapslices(x->mean(skipmissing(x)), ds[var][:,:,:], dims = [1,2])[:]
    else
        ds_spmean = mapslices(x->mean(skipmissing(x)), ds[var][:,:,idx], dims = [1,2])[:]
    end
    return transpose(ds_spmean)
end

"""
    tmean(ds, var, idx)

Calculate temporal mean across dimension 3 of NetCDF data.
"""
function tmean(ds, var, idx)
    if idx == "all"
        ds_tmean = mapslices(x->mean(skipmissing(x)), ds[var][:,:,:], dims = [3])[:,:,1]
    else
        ds_tmean = mapslices(x->mean(skipmissing(x)), ds[var][:,:,idx], dims = [3])[:,:,1]
    end
    return transpose(ds_tmean)
end

"""
    spsum(ds, var, idx)

Calculate spatial sum across dimensions 1 and 2 of NetCDF data.
"""
function spsum(ds, var, idx)
    if idx == "all"
        ds_spmean = mapslices(x->sum(skipmissing(x)), ds[var][:,:,:], dims = [1,2])[:]
    else
        ds_spmean = mapslices(x->sum(skipmissing(x)), ds[var][:,:,idx], dims = [1,2])[:]
    end
    ds_spmean_format = replace(ds_spmean, 0 => missing)
    return transpose(ds_spmean_format)
end

"""
    tsum(ds, var, idx)

Calculate temporal sum across dimension 3 of NetCDF data.
"""
function tsum(ds, var, idx)
    if idx == "all"
        ds_tmean = mapslices(x->sum(skipmissing(x)), ds[var][:,:,:], dims = [3])[:,:,1]
    else
        ds_tmean = mapslices(x->sum(skipmissing(x)), ds[var][:,:,idx], dims = [3])[:,:,1]
    end
    ds_tmean_format = replace(ds_tmean, 0 => missing)
    return transpose(ds_tmean_format)
end

"""
    tdiff_mean(ds1, ds2, var, idx)

Calculate temporal mean difference between two datasets.
"""
function tdiff_mean(ds1, ds2, var, idx)
    if idx == "all"
        out = mapslices(x->mean(skipmissing(x)), ds1[var][:,:,:], dims = [3])[:,:,1] - 
              mapslices(x->mean(skipmissing(x)), ds2[var][:,:,:], dims = [3])[:,:,1]
    else
        out = mapslices(x->mean(skipmissing(x)), ds1[var][:,:,idx], dims = [3])[:,:,1] - 
              mapslices(x->mean(skipmissing(x)), ds2[var][:,:,idx], dims = [3])[:,:,1]
    end
    return transpose(out)
end

"""
    tdiff_sum(ds1, ds2, var, idx)

Calculate temporal sum difference between two datasets.
"""
function tdiff_sum(ds1, ds2, var, idx)
    if idx == "all"
        out = mapslices(x->sum(skipmissing(x)), ds1[var][:,:,:], dims = [3])[:,:,1] - 
              mapslices(x->sum(skipmissing(x)), ds2[var][:,:,:], dims = [3])[:,:,1]
    else
        out = mapslices(x->sum(skipmissing(x)), ds1[var][:,:,idx], dims = [3])[:,:,1] - 
              mapslices(x->sum(skipmissing(x)), ds2[var][:,:,idx], dims = [3])[:,:,1]
    end
    out_format = replace(out, 0 => missing)
    return transpose(out_format)
end

"""
    na_rm(vec)

Remove missing values from a vector.
"""
function na_rm(vec)
    return collect(skipmissing(vec))
end

"""
    Dates_noleap(datetime_inp)

Convert NoLeap calendar dates to standard Date format.
"""
function Dates_noleap(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple, 1), getindex.(dt_tuple, 2), getindex.(dt_tuple, 3))
    return date_out
end

"""
    calc_exc_mda8(df)

Calculate exceedances where values exceed 120 threshold.
"""
function calc_exc_mda8(df)
    return ifelse.(df .< 120, 0, 1)
end

"""
    get_date_ranges(start_year, end_year)

Generate standard date ranges for historical and future periods.
"""
function get_date_ranges()
    dt_hist_noleap = DateTimeNoLeap(2007,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2016,12,31,23,00,00)
    dt_hist_noleap = collect(dt_hist_noleap)
    dt_hist_leap = DateTime(2007,01,01,00,00,00): Hour(1) : DateTime(2016,12,31,23,00,00)
    dt_hist_leap = collect(dt_hist_leap)
    dt_rcp26_noleap = DateTimeNoLeap(2007,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2017,01,03,23,00,00)
    dt_rcp26_noleap = collect(dt_rcp26_noleap)
    dt_nf_noleap = DateTimeNoLeap(2026,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2035,12,31,23,00,00)
    dt_nf_noleap = collect(dt_nf_noleap)
    dt_ff_noleap = DateTimeNoLeap(2046,01,01,00,00,00): Hour(1) : DateTimeNoLeap(2055,12,31,23,00,00)
    dt_ff_noleap = collect(dt_ff_noleap)
    
    return Dict(
        "hist_noleap" => dt_hist_noleap,
        "hist_leap" => dt_hist_leap,
        "rcp26_noleap" => dt_rcp26_noleap,
        "nf_noleap" => dt_nf_noleap,
        "ff_noleap" => dt_ff_noleap
    )
end

"""
    create_season_subsets(dates)

Create subsets of data by meteorological seasons.
"""
function create_season_subsets(dates)
    season_djf = ["December", "January", "February"]
    season_mam = ["March", "April", "May"]
    season_jja = ["June", "July", "August"]
    season_son = ["September", "October", "November"]
    
    seasons = [season_djf, season_mam, season_jja, season_son]
    
    indices = []
    for season in seasons
        idx = findall(in(season).(monthname.(dates)))
        push!(indices, idx)
    end
    
    return Dict(
        "DJF" => indices[1],
        "MAM" => indices[2],
        "JJA" => indices[3],
        "SON" => indices[4]
    )
end

"""
    getvec(ds, var)

Extract data from a NetCDF dataset as a vector.
"""
function getvec(ds, var)
    return ds[var][:]
end

"""
    read_nc_data(file_path, var_names)

Read variables from a NetCDF file.
"""
function read_nc_data(file_path, var_names)
    ds = Dataset(file_path)
    result = Dict()
    
    for var in var_names
        if var in keys(ds)
            result[var] = ds[var][:]
        end
    end
    
    close(ds)
    return result
end

"""
    read_csv_data(file_path, missing_string="NA")

Read data from a CSV file as a DataFrame.
"""
function read_csv_data(file_path; missing_string="NA") 
    return CSV.read(file_path, DataFrame, missingstring=missing_string)
end

"""
    filter_cols_by_value(df, filter_col, max_value)

Filter DataFrame columns based on a value threshold.
"""
function filter_cols_by_value(df, filter_col, max_value)
    indices = findall(df[!, filter_col] .< max_value)
    return indices
end

end # module DataProcessing

#####################################
# Visualization Module
#####################################
module Visualization

using NCDatasets, Plots, StatsPlots, ColorSchemes, DataFrames, Statistics

export plot_heatmap, plot_density_comparison, plot_boxplot_comparison,
       map_heat_att, map_heat_att_diff, 
       get_colorscheme, create_multi_panel

"""
    plot_heatmap(lon, lat, data; colormap=:viridis, clim=nothing, title="")

Create a heatmap of spatial data.
"""
function plot_heatmap(lon, lat, data; colormap=:viridis, clim=nothing, title="")
    if isnothing(clim)
        clim = (minimum(skipmissing(data)), maximum(skipmissing(data)))
    end
    
    p = heatmap(lon, lat, data, 
                colormap=colormap, 
                clim=clim,
                title=title,
                xlabel="Longitude [°]",
                ylabel="Latitude [°]")
    return p
end

"""
    plot_density_comparison(data_dict; labels=nothing, title="Density Comparison", xlabel="Value", kwargs...)

Create density plots for comparing multiple datasets.
"""
function plot_density_comparison(data_dict; labels=nothing, title="Density Comparison", xlabel="Value", kwargs...)
    if isnothing(labels)
        labels = keys(data_dict)
    end
    
    p = plot(title=title, xlabel=xlabel, ylabel="Density"; kwargs...)
    
    for (i, (key, data)) in enumerate(data_dict)
        density!(p, collect(skipmissing(data)), label=labels[i])
    end
    
    return p
end

"""
    plot_boxplot_comparison(data_dict; grouping=nothing, labels=nothing, title="", ylabel="", kwargs...)

Create boxplots for comparing multiple datasets, optionally grouped.
"""
function plot_boxplot_comparison(data_dict; grouping=nothing, labels=nothing, title="", ylabel="", kwargs...)
    data_array = []
    
    if isnothing(labels)
        labels = collect(keys(data_dict))
    end
    
    for key in keys(data_dict)
        push!(data_array, collect(skipmissing(data_dict[key])))
    end
    
    if isnothing(grouping)
        p = boxplot(data_array, label=labels, title=title, ylabel=ylabel; kwargs...)
    else
        # TODO: Implement grouped boxplots based on grouping parameter
        p = boxplot(data_array, label=labels, title=title, ylabel=ylabel; kwargs...)
    end
    
    return p
end

"""
    map_heat_att(filen, nckey, cs, clim_p, title)

Create a heatmap from NetCDF data with specified styling.
"""
function map_heat_att(filen, nckey, cs, clim_p; ptitle="")
    ds = Dataset(filen)
    lon = ds["lon"][:]
    lat = ds["lat"][:]
    
    p = heatmap(lon, lat, transpose(ds[nckey]), colormap=cs, colorrange=clim_p)
    title!(ptitle)
    xlabel!("Longitude [°]")
    ylabel!("Latitude [°]")
    close(ds)
    return p
end

"""
    map_heat_att_diff(filen, filen2, nckey, cs, clim_p)

Create a difference heatmap between two NetCDF files.
"""
function map_heat_att_diff(filen, filen2, nckey, cs, clim_p)
    ds = Dataset(filen)
    ds2 = Dataset(filen2)
    lon = ds["lon"][:]
    lat = ds["lat"][:]
    
    p = heatmap(lon, lat, ds[nckey] - ds2[nckey], colormap=cs, colorrange=clim_p)
    close(ds)
    close(ds2)
    return p
end

"""
    get_colorscheme(name, n=20; categorical=false, rev=false)

Get a pre-configured colorscheme.
"""
function get_colorscheme(name, n=20; categorical=false, rev=false)
    return cgrad(name, n, categorical=categorical, rev=rev)
end

"""
    create_multi_panel(plots, ncols=2; kwargs...)

Create a multi-panel figure from individual plots.
"""
function create_multi_panel(plots, ncols=2; resolution=(1200,800), kwargs...)
    fig = plot(plots..., layout=(ceil(Int, length(plots)/ncols), ncols), size=resolution; kwargs...)
    return fig
end

end # module Visualization

#####################################
# Analysis Module
#####################################
module Analysis

using NCDatasets, Dates, Statistics, DataFrames

export season_filter, calc_statistical_metrics, 
       calculate_exceedances, aggregate_by_season,
       filter_stations_by_altitude

"""
    season_filter(dates, season)

Filter indices for a specific season.
"""
function season_filter(dates, season)
    season_map = Dict(
        "DJF" => ["December", "January", "February"],
        "MAM" => ["March", "April", "May"],
        "JJA" => ["June", "July", "August"],
        "SON" => ["September", "October", "November"]
    )
    
    if season in keys(season_map)
        return findall(in(season_map[season]).(monthname.(dates)))
    else
        error("Unknown season: $season. Use DJF, MAM, JJA, or SON.")
    end
end

"""
    calc_statistical_metrics(obs, model)

Calculate statistical metrics between observations and model data.
"""
function calc_statistical_metrics(obs, model)
    clean_obs = collect(skipmissing(obs))
    clean_model = collect(skipmissing(model))
    
    # Make sure lengths match
    min_length = min(length(clean_obs), length(clean_model))
    clean_obs = clean_obs[1:min_length]
    clean_model = clean_model[1:min_length]
    
    bias = mean(clean_model - clean_obs)
    rmse = sqrt(mean((clean_model - clean_obs).^2))
    corr = cor(clean_obs, clean_model)
    
    return Dict(
        "bias" => bias,
        "rmse" => rmse,
        "correlation" => corr
    )
end

"""
    calculate_exceedances(data, threshold=120)

Calculate exceedances over a threshold.
"""
function calculate_exceedances(data, threshold=120)
    exc = copy(data)
    exc[exc .< threshold] .= 0
    exc[exc .>= threshold] .= 1
    return exc
end

"""
    aggregate_by_season(data, dates)

Aggregate data by meteorological seasons.
"""
function aggregate_by_season(data, dates)
    seasons = ["DJF", "MAM", "JJA", "SON"]
    result = Dict()
    
    for season in seasons
        indices = season_filter(dates, season)
        if length(indices) > 0
            seasonal_data = data[indices, :]
            result[season] = mean(seasonal_data, dims=1)[1, :]
        else
            result[season] = missing
        end
    end
    
    return result
end

"""
    filter_stations_by_altitude(meta_df, max_altitude=1500)

Filter stations based on altitude threshold.
"""
function filter_stations_by_altitude(meta_df, max_altitude=1500)
    return findall(meta_df[:, :Hoehe] .< max_altitude)
end

end # module Analysis

#####################################
# NetCDF Module
#####################################
module NetCDFTools

using NCDatasets, Dates, OrderedCollections

export create_nc_exceedance, write_nc_data

"""
    create_nc_exceedance(output_path, lon, lat, time_values, data; var_name="O3")

Create a NetCDF file with exceedance data.
"""
function create_nc_exceedance(output_path, lon, lat, time_values, data; var_name="O3")
    ds = NCDataset(output_path, "c")
    
    # Dimensions
    ds.dim["lon"] = length(lon)
    ds.dim["lat"] = length(lat)
    ds.dim["time"] = length(time_values)
    
    # Variables
    nclon = defVar(ds, "lon", Float64, ("lon",), attrib = OrderedDict(
        "units"     => "degrees",
        "long_name" => "longitude"
    ))
    
    nclat = defVar(ds, "lat", Float64, ("lat",), attrib = OrderedDict(
        "units"     => "degrees",
        "long_name" => "latitude"
    ))
    
    nctime = defVar(ds, "time", Float64, ("time",), attrib = OrderedDict(
        "units"     => "minutes since 2007-01-01 00:00:00",
        "long_name" => "time",
        "calendar"  => "standard"
    ))
    
    ncvar = defVar(ds, var_name, Float32, ("lon", "lat", "time"), attrib = OrderedDict(
        "units"       => "ug/m3",
        "_FillValue"  => Float32(-1.0),
        "long_name"   => "$var_name bias corrected"
    ))
    
    # Assign data
    nclon[:] = lon
    nclat[:] = lat
    nctime[:] = time_values
    ncvar[:] = data
    
    close(ds)
    return true
end

"""
    write_nc_data(output_path, data_dict, dim_dict; attributes=Dict())

Write data to NetCDF file.
"""
function write_nc_data(output_path, data_dict, dim_dict; attributes=Dict())
    ds = NCDataset(output_path, "c")
    
    # Create dimensions
    for (dim_name, dim_size) in dim_dict
        ds.dim[dim_name] = dim_size
    end
    
    # Create and assign variables
    for (var_name, var_data) in data_dict
        var_dims = size(var_data)
        dim_names = []
        
        for (i, dim_size) in enumerate(var_dims)
            for (dim_name, size_val) in dim_dict
                if size_val == dim_size && !(dim_name in dim_names)
                    push!(dim_names, dim_name)
                    break
                end
            end
        end
        
        # Create variable with attributes if present
        var_attrs = OrderedDict()
        if var_name in keys(attributes)
            var_attrs = attributes[var_name]
        end
        
        nc_var = defVar(ds, var_name, eltype(var_data), tuple(dim_names...), attrib=var_attrs)
        nc_var[:] = var_data
    end
    
    close(ds)
    return true
end

end # module NetCDFTools

# Export modules
export DataProcessing, Visualization, Analysis, NetCDFTools

end # module GOLEM