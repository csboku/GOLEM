using NCDatasets, CairoMakie, Missings, Shapefile

# --- 1. Load and Prepare Data (same as before) ---
println("Loading data...")
ncin = Dataset("CAMS-REG-ANT_EUR_0.05x0.1_anthro_nox_v7.0_yearly.nc")
emis = ncin["SumAllSectors"][:,:,1]
lon = ncin["lon"][:]
lat = ncin["lat"][:]
emis_plot = replace(emis, 0.0 => NaN)

# --- 2. Load the NUTS Shapefile Data ---
println("Loading NUTS boundaries...")
# Make sure the .shp file is in the same folder or provide the full path
nuts_path = "/home/cschmidt/data/shp/NUTS_RG_01M_2024_4326.shp/NUTS_RG_01M_2024_4326.shp"
table = Shapefile.Table(nuts_path)

# --- 3. Create Plot for Switzerland with NUTS lines ---
println("Creating Switzerland plot...")
switzerland_limits = (5.8, 10.6, 45.7, 47.9)

fig_swiss = Figure(size = (800, 600))
ax_swiss = Axis(fig_swiss[1, 1],
          xlabel = "Longitude",
          ylabel = "Latitude",
          title = "CAMS NOx Emissions over Switzerland",
          limits = switzerland_limits)

# First, draw the heatmap as before
hm_swiss = heatmap!(ax_swiss, lon, lat, emis_plot,
              colorscale = log10, colormap = :batlow)

# Now, iterate through the shapes and plot them
println("Drawing NUTS lines...")
for shape in table
    # We only want to plot the shapes for Switzerland ('CH')
    # This checks the country code for each shape
    if shape.CNTR_CODE == "CH"
        lines!(ax_swiss, shape.geometry, color = :black, linewidth = 1.0)
    end
end

Colorbar(fig_swiss[1, 2], hm_swiss, label = "Emissions, kg m⁻² s⁻¹ (log₁₀ scale)")

davos_limits = (9.6, 10.1, 46.6, 47.0)

fig_swiss = Figure(size = (800, 600))
ax_swiss = Axis(fig_swiss[1, 1],
          xlabel = "Longitude",
          ylabel = "Latitude",
          title = "CAMS NOx Emissions over Davos 2021",
          limits = davos_limits)

# First, draw the heatmap as before
hm_swiss = heatmap!(ax_swiss, lon, lat, emis_plot,
              colorscale = log10, colormap = :batlow)

# Now, iterate through the shapes and plot them
println("Drawing NUTS lines...")
for shape in table
    # We only want to plot the shapes for Switzerland ('CH')
    # This checks the country code for each shape
    if shape.CNTR_CODE == "CH"
        lines!(ax_swiss, shape.geometry, color = :black, linewidth = 1.0)
    end
end

Colorbar(fig_swiss[1, 2], hm_swiss, label = "Emissions, kg m⁻² s⁻¹ (log₁₀ scale)")



save("cams_nox_heatmap_davos_nuts.png", fig_swiss)
println("Switzerland plot with NUTS lines saved!")
