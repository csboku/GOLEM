using NCDatasets,CairoMakie,Missings,Shapefile

shp_in = Shapefile.Table("/home/cschmidt/data/shp/NUTS_RG_01M_2024_4326.shp/NUTS_RG_01M_2024_4326.shp")
shp_in
shp_in.NUTS_ID



ncin = Dataset("CAMS-REG-ANT_EUR_0.05x0.1_anthro_nox_v7.0_yearly.nc")
emis = ncin["SumAllSectors"][:,:,1]
lon = ncin["lon"][:]
lat = ncin["lat"][:]

emis = replace(emis, 0.0 => NaN)


fig = Figure(size = (800, 600))
ax = Axis(fig[1, 1],
          xlabel = "Longitude",
          ylabel = "Latitude",
          title = "CAMS Anthropogenic NOx Emissions 2021")

hm = heatmap!(ax, lon, lat, emis, colorscale = log10,colormap=:batlow)
Colorbar(fig[1, 2], hm, label = "Emissions, kg m⁻² s⁻¹ (log₁₀ scale)")

save("cams_nox_heatmap.png", fig)


