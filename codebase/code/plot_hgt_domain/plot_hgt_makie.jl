using NCDatasets,Shapefile,DelimitedFiles,CSV,DataFrames,CairoMakie

cd(@__DIR__)

hgt_in = Dataset("/sto2/data/lenian/data/attain/hgt/att_hgt_latlon.nc")

shp_in = Shapefile.Table("/sto2/data/lenian/data/shp/NUTS_RG_10M_2021_4326.shp/NUTS_RG_10M_2021_4326.shp")

meta_in = CSV.read("meta_meas.csv",DataFrame)

#hgt_lon = hgt_in["lon"][:,1]
#hgt_lat = hgt_in["lat"][1,:]
hgt_lon = hgt_in["lon"][:]
hgt_lat = hgt_in["lat"][:]
hgt= hgt_in["HGT"][:,:,1]

zoom_box = [
    [9.3, 46.0],  # Lower left corner
    [17.3, 46.0], # Lower right corner
    [17.3, 49.4], # Upper right corner
    [9.3, 49.4],  # Upper left corner
    [9.3, 46.0]   # Back to start to close the box
]







fig1 = Figure(size=(600,800))
ax1 = Axis(fig1[1,1],ylabel="Latitude",xlabel="Longitude")
hm1 = heatmap!(hgt_lon,hgt_lat,hgt,colormap=:terrain)
xlims!(ax1,0.5,28.5)
ylims!(ax1,42.5,57)
for i in 1:length(hgt_lon)
    print(i)
    lines!([hgt_lon[i],hgt_lon[i]],[hgt_lat[1],hgt_lat[end]], color=:white,linewidth=0.5,alpha=0.5)
end
for i in 1:length(hgt_lat)
    print(i)
    lines!([hgt_lon[1],hgt_lon[end]],[hgt_lat[i],hgt_lat[i]], color=:white,linewidth=0.5,alpha=0.5)
end
poly!(Shapefile.shapes(shp_in)[shp_in.LEVL_CODE .== 0],color=:transparent,strokecolor=:black,strokewidth=1)

ax2 = Axis(fig1[2,1],ylabel="Latitude",xlabel="Longitude")
heatmap!(hgt_lon,hgt_lat,hgt,colormap=:terrain)
xlims!(ax2,9.3,17.3)
ylims!(ax2,46,49.4)
for i in 1:length(hgt_lon)
    print(i)
    lines!([hgt_lon[i],hgt_lon[i]],[hgt_lat[1],hgt_lat[end]], color=:white,linewidth=0.5,alpha=0.5)
end
for i in 1:length(hgt_lat)
    print(i)
    lines!([hgt_lon[1],hgt_lon[end]],[hgt_lat[i],hgt_lat[i]], color=:white,linewidth=0.5,alpha=0.5)
end
poly!(Shapefile.shapes(shp_in)[shp_in.LEVL_CODE .== 0],color=:transparent,strokecolor=:black,strokewidth=1)
scatter!(meta_in[:,:LAENGE],meta_in[:,:BREITE],markersize=10,color=:fuchsia,label= "O₃ measurement stations")
axislegend(ax2,position = :lt)
Colorbar(fig1[:,2],hm1,label="Terrain height [m]",ticks=[0:500:3000;])
fig1



save("fig1_hgt_domain_vert.png",fig1)





fig1 = Figure(size=(900,300))
ax1 = Axis(fig1[1,1],ylabel="Latitude",xlabel="Longitude")
hm1 = heatmap!(hgt_lon,hgt_lat,hgt,colormap=:terrain)
xlims!(ax1,0.5,28.5)
ylims!(ax1,42.5,57)
for i in 1:length(hgt_lon)
    print(i)
    lines!([hgt_lon[i],hgt_lon[i]],[hgt_lat[1],hgt_lat[end]], color=:white,linewidth=0.5,alpha=0.5)
end
for i in 1:length(hgt_lat)
    print(i)
    lines!([hgt_lon[1],hgt_lon[end]],[hgt_lat[i],hgt_lat[i]], color=:white,linewidth=0.5,alpha=0.5)
end
poly!(Shapefile.shapes(shp_in)[shp_in.LEVL_CODE .== 0],color=:transparent,strokecolor=:black,strokewidth=1)

lines!(ax1,
[point[1] for point in zoom_box],
[point[2] for point in zoom_box],
color=:fuchsia,
linewidth=2.5,
linestyle=:solid)

ax2 = Axis(fig1[1,2],ylabel="Latitude",xlabel="Longitude")
heatmap!(hgt_lon,hgt_lat,hgt,colormap=:terrain)
xlims!(ax2,9.3,17.3)
ylims!(ax2,46,49.4)
for i in 1:length(hgt_lon)
    print(i)
    lines!([hgt_lon[i],hgt_lon[i]],[hgt_lat[1],hgt_lat[end]], color=:white,linewidth=0.5,alpha=0.5)
end
for i in 1:length(hgt_lat)
    print(i)
    lines!([hgt_lon[1],hgt_lon[end]],[hgt_lat[i],hgt_lat[i]], color=:white,linewidth=0.5,alpha=0.5)
end
poly!(Shapefile.shapes(shp_in)[shp_in.LEVL_CODE .== 0],color=:transparent,strokecolor=:black,strokewidth=1)
scatter!(meta_in[:,:LAENGE],meta_in[:,:BREITE],markersize=10,color=:fuchsia,label= "O₃ measurement stations")
axislegend(ax2,position = :lt)
Colorbar(fig1[:,3],hm1,label="Terrain height [m]",ticks=[0:500:3000;])
fig1

save("fig1_hgt_domain_horiz.png",fig1)