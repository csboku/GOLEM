# GOLEM Libraries Documentation

This document provides an overview of the key functions in the GOLEM libraries for Julia, R, and Python.

## Table of Contents
- [Julia Library (GOLEM.jl)](#julia-library-golemjl)
- [R Library (GOLEM_R.R)](#r-library-golem_rr)
- [Python Library (GOLEM_python.py)](#python-library-golem_pythonpy)

## Julia Library (GOLEM.jl)

GOLEM.jl is organized into four modules: DataProcessing, Visualization, Analysis, and NetCDFTools.

### DataProcessing Module

| Function | Description | Parameters |
|----------|-------------|------------|
| `spmean(ds, var, idx)` | Calculate spatial mean across dimensions 1 and 2 | `ds`: Dataset, `var`: Variable name, `idx`: Time indices or "all" |
| `tmean(ds, var, idx)` | Calculate temporal mean across dimension 3 | `ds`: Dataset, `var`: Variable name, `idx`: Time indices or "all" |
| `spsum(ds, var, idx)` | Calculate spatial sum across dimensions 1 and 2 | `ds`: Dataset, `var`: Variable name, `idx`: Time indices or "all" |
| `tsum(ds, var, idx)` | Calculate temporal sum across dimension 3 | `ds`: Dataset, `var`: Variable name, `idx`: Time indices or "all" |
| `tdiff_mean(ds1, ds2, var, idx)` | Calculate temporal mean difference between datasets | `ds1`, `ds2`: Datasets, `var`: Variable name, `idx`: Time indices |
| `na_rm(vec)` | Remove missing values from a vector | `vec`: Input vector |
| `Dates_noleap(datetime_inp)` | Convert NoLeap calendar dates to standard Date format | `datetime_inp`: NoLeap datetime array |
| `calc_exc_mda8(df)` | Calculate exceedances where values exceed 120 threshold | `df`: Input data |
| `get_date_ranges()` | Generate standard date ranges for historical and future periods | None |
| `create_season_subsets(dates)` | Create subsets of data by meteorological seasons | `dates`: Array of dates |
| `read_nc_data(file_path, var_names)` | Read variables from a NetCDF file | `file_path`: Path to file, `var_names`: List of variables |
| `read_csv_data(file_path, missing_string)` | Read data from a CSV file as a DataFrame | `file_path`: Path to file, `missing_string`: NA value string |

### Visualization Module

| Function | Description | Parameters |
|----------|-------------|------------|
| `plot_heatmap(lon, lat, data, ...)` | Create a heatmap of spatial data | `lon`: Longitudes, `lat`: Latitudes, `data`: Data array |
| `plot_density_comparison(data_dict, ...)` | Create density plots for comparing multiple datasets | `data_dict`: Dictionary of datasets |
| `plot_boxplot_comparison(data_dict, ...)` | Create boxplots for comparing multiple datasets | `data_dict`: Dictionary of datasets |
| `map_heat_att(filen, nckey, cs, clim_p, ...)` | Create a heatmap from NetCDF data | `filen`: File path, `nckey`: Variable, `cs`: Colorscheme |
| `map_heat_att_diff(filen, filen2, nckey, cs, clim_p)` | Create a difference heatmap between files | `filen`, `filen2`: File paths, `nckey`: Variable |
| `get_colorscheme(name, n, ...)` | Get a pre-configured colorscheme | `name`: Colorscheme name, `n`: Number of colors |
| `create_multi_panel(plots, ncols, ...)` | Create a multi-panel figure from plots | `plots`: List of plots, `ncols`: Number of columns |

### Analysis Module

| Function | Description | Parameters |
|----------|-------------|------------|
| `season_filter(dates, season)` | Filter indices for a specific season | `dates`: Date array, `season`: Season code (DJF, MAM, JJA, SON) |
| `calc_statistical_metrics(obs, model)` | Calculate statistical metrics | `obs`: Observations, `model`: Model data |
| `calculate_exceedances(data, threshold)` | Calculate exceedances over a threshold | `data`: Input data, `threshold`: Threshold value |
| `aggregate_by_season(data, dates)` | Aggregate data by meteorological seasons | `data`: Data array, `dates`: Date array |
| `filter_stations_by_altitude(meta_df, max_altitude)` | Filter stations by altitude | `meta_df`: Station metadata, `max_altitude`: Max altitude |

### NetCDFTools Module

| Function | Description | Parameters |
|----------|-------------|------------|
| `create_nc_exceedance(output_path, lon, lat, time_values, data, ...)` | Create NetCDF with exceedance data | `output_path`: Output file, `lon`, `lat`, `time_values`: Dimensions |
| `write_nc_data(output_path, data_dict, dim_dict, ...)` | Write data to NetCDF file | `output_path`: Output file, `data_dict`: Data, `dim_dict`: Dimensions |

## R Library (GOLEM_R.R)

The GOLEM R library is organized into functional modules for data processing, visualization, spatial analysis, and statistics.

### Data Processing Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `na_count(data, dimension)` | Count NA values in columns or rows | `data`: Input data, `dimension`: 1 for rows, 2 for columns |
| `filter_na(data, na_threshold, dimension)` | Filter by NA count | `data`: Input data, `na_threshold`: Max NA count |
| `read_data_csv(file_path, na_strings)` | Read CSV data | `file_path`: Input file, `na_strings`: NA value strings |
| `find_files(dir_path, pattern, full_names)` | Find files matching pattern | `dir_path`: Directory, `pattern`: File pattern |
| `filter_by_altitude(data, alt_col, max_alt)` | Filter data by altitude | `data`: Station data, `alt_col`: Altitude column name |

### Visualization Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `plot_density_comparison(data_list, ...)` | Create density plot for multiple datasets | `data_list`: Named list of data vectors |
| `plot_boxplot_comparison(data_list, ...)` | Create boxplot for multiple datasets | `data_list`: Named list of data vectors |
| `plot_exceedance_bars(data_list, categories, ...)` | Create bar plot for exceedances | `data_list`: Named list of data vectors |

### Spatial Analysis Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `map_raster_to_polygons(raster_path, shapefile_path, ...)` | Map raster to polygon areas | `raster_path`: Raster file, `shapefile_path`: Shapefile path |
| `extract_points_from_raster(raster_path, points, ...)` | Extract point values from raster | `raster_path`: Raster file, `points`: Point coordinates |
| `simplify_shapefile(shapefile_path, tolerance, ...)` | Simplify shapefile for processing | `shapefile_path`: Input shapefile, `tolerance`: Simplification level |

### Statistical Analysis Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `calc_exceedances(data, threshold)` | Calculate threshold exceedances | `data`: Input data, `threshold`: Threshold value |
| `calc_stats_metrics(obs, model)` | Calculate statistical metrics | `obs`: Observations, `model`: Model data |
| `aggregate_by_season(data, date_col, value_cols)` | Aggregate data by season | `data`: Input data, `date_col`: Date column |
| `compare_models(ref_data, model_list)` | Compare multiple models to reference | `ref_data`: Reference data, `model_list`: List of model data |

## Python Library (GOLEM_python.py)

The Python library is structured as classes with static methods for different functionalities.

### DataProcessing Class

| Method | Description | Parameters |
|--------|-------------|------------|
| `remove_missing(data)` | Remove missing values from array | `data`: Input array |
| `calculate_exceedances(data, threshold)` | Calculate exceedances over threshold | `data`: Input array, `threshold`: Threshold value |
| `read_netcdf(file_path, variables)` | Read data from NetCDF file | `file_path`: Input file, `variables`: Variable names |
| `filter_by_altitude(data, alt_col, max_alt)` | Filter dataframe by altitude | `data`: Input dataframe, `alt_col`: Altitude column |
| `filter_by_season(data, date_col, season)` | Filter dataframe by season | `data`: Input dataframe, `date_col`: Date column |
| `aggregate_by_season(data, date_col, value_col)` | Aggregate data by season | `data`: Input dataframe, `date_col`: Date column |

### Visualization Class

| Method | Description | Parameters |
|--------|-------------|------------|
| `setup_figure(figsize, style)` | Set up a matplotlib figure | `figsize`: Figure size, `style`: Plot style |
| `setup_multi_panel(nrows, ncols, ...)` | Set up multi-panel figure | `nrows`: Number of rows, `ncols`: Number of columns |
| `create_boxplot_comparison(ax, data_dict, ...)` | Create comparison boxplot | `ax`: Matplotlib axes, `data_dict`: Data dictionary |
| `create_bar_comparison(ax, data_dict, ...)` | Create comparison bar chart | `ax`: Matplotlib axes, `data_dict`: Data dictionary |
| `plot_density_comparison(data_dict, ...)` | Create density plots | `data_dict`: Data dictionary |
| `save_figure(fig, filename, ...)` | Save figure in multiple formats | `fig`: Figure object, `filename`: Output filename |

### Statistics Class

| Method | Description | Parameters |
|--------|-------------|------------|
| `calc_statistical_metrics(obs, model)` | Calculate statistical metrics | `obs`: Observations, `model`: Model data |
| `compare_models(ref_data, model_dict)` | Compare multiple models | `ref_data`: Reference data, `model_dict`: Model data dictionary |
| `calc_exceedance_stats(data_dict, ...)` | Calculate exceedance statistics | `data_dict`: Data dictionary, `threshold`: Threshold value |

### Spatial Class

| Method | Description | Parameters |
|--------|-------------|------------|
| `extract_points(raster_data, lons, lats, points)` | Extract values at specific points | `raster_data`: Raster array, `points`: Point coordinates |
| `raster_difference(raster1, raster2)` | Calculate difference between rasters | `raster1`, `raster2`: Raster arrays |

## Usage Examples

See the example scripts for practical applications of these functions:
- `example_usage.jl` for Julia
- `example_usage_R.R` for R
- `example_usage_python.py` for Python

These examples demonstrate how to process data, create visualizations, and perform statistical analyses using the GOLEM libraries.