using GOLEM

# Import specific modules for cleaner usage
using GOLEM.DataProcessing
using GOLEM.Visualization
using GOLEM.Analysis
using GOLEM.NetCDFTools

# Example 1: Process netCDF data and calculate spatial/temporal means
println("Example 1: Data processing")
datapath = "/home/cschmidt/data/attain/output_bias_correction"
exc_files = readdir(datapath*"/bias_exc/", join=true)

# Read first file
file_path = exc_files[1]
ds = NCDatasets.Dataset(file_path)

# Get dimensions
lat = ds["lat"][:]
lon = ds["lon"][:]

# Calculate spatial mean of ozone for all time indices
o3_spmean = spmean(ds, "O3", "all")
println("Spatial mean shape: ", size(o3_spmean))

# Calculate temporal mean for the variable
o3_tmean = tmean(ds, "O3", "all")
println("Temporal mean shape: ", size(o3_tmean))

# Clean up
close(ds)

# Example 2: Working with date ranges
println("\nExample 2: Working with date ranges")
date_ranges = get_date_ranges()
hist_dates = date_ranges["hist_leap"]
println("Historical period: ", first(hist_dates), " to ", last(hist_dates))

# Create season subsets
seasons = create_season_subsets(hist_dates)
println("JJA (summer) indices count: ", length(seasons["JJA"]))

# Example 3: Visualizing data
println("\nExample 3: Visualization")
using Random
Random.seed!(123)

# Generate some mock data
mock_data = rand(75, 26) .* 100
lon_vals = range(10.0, 20.0, length=75)
lat_vals = range(45.0, 50.0, length=26)

# Create a simple heatmap
println("Creating heatmap plot...")
plt = plot_heatmap(lon_vals, lat_vals, mock_data, 
                  title="Mock O3 Concentration", 
                  colormap=:viridis)

# Create a density comparison
model_data = Dict(
    "Measurements" => rand(100) .* 80 .+ 40,
    "WRF" => rand(100) .* 70 .+ 50,
    "CAMx" => rand(100) .* 60 .+ 60
)

println("Creating density comparison plot...")
density_plt = plot_density_comparison(model_data, 
                                    title="O3 Concentration Distribution", 
                                    xlabel="Concentration [μg/m³]")

# Example 4: Calculating statistics and exceedances
println("\nExample 4: Statistics and exceedances")
obs_data = rand(100) .* 80 .+ 40
model_data = obs_data .+ rand(-20:20, 100)

metrics = calc_statistical_metrics(obs_data, model_data)
println("Statistical metrics:")
for (key, value) in metrics
    println("  $key: $value")
end

# Calculate exceedances
exceedances = calculate_exceedances(model_data, 120)
exceed_count = sum(exceedances)
println("Number of exceedances: $exceed_count out of 100")

println("\nGOLEM library examples completed")