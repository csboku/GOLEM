using NCDatasets,CairoMakie,Measures,Shapefile,DelimitedFiles,CSV,DataFrames

cd(@__DIR__)

hgt_in = Dataset("/home/cschmidt/data/attain/hgt/att_hgt_latlon.nc")

shp_in = Shapefile.Table("/home/cschmidt/data/shp/NUTS_RG_10M_2021_4326.shp/NUTS_RG_10M_2021_4326.shp")

hgt_lon = hgt_in["lon"][:,1]
hgt_lat = hgt_in["lat"][1,:]
hgt_lon = hgt_in["lon"][:]
hgt_lat = hgt_in["lat"][:]
hgt= hgt_in["HGT"][:,:,1]

Shapefile.shapes(shp_in)

shp_in.LEVL_CODE .== 0

shp_in[shp_in.LEVL_CODE .== 0] |> plot

shp_in.geometry[shp_in.EU_FLAG .== "T" ] |> plot

gr()

h_p = heatmap(hgt_lon,hgt_lat,transpose(hgt),fill=:terrain, colorbar_title="Terrain Height [m]",size=(900,600),right_margin = 4mm, left_margin=4mm,framestyle=:box)
for i in 1:length(hgt_lon)
    print(i)
    plot!([hgt_lon[i],hgt_lon[i]],[hgt_lat[1],hgt_lat[end]], label=false, c=:white, linewitdth = 0.4,linealpha=0.3)
end
for i in 1:length(hgt_lat)
    print(i)
    plot!([hgt_lon[1],hgt_lon[end]],[hgt_lat[i],hgt_lat[i]], label=false, c=:white, linewitdth = 0.4,linealpha=0.3)
end
xlabel!("lon [°]")
ylabel!("lat [°]")
plot!(Shapefile.shapes(shp_in)[shp_in.LEVL_CODE .== 0],fc=:transparent)
xlims!(9.3,17.3)
ylims!(46,49.4)
xlims!(0.5,28.5)
ylims!(42.5,57)
vline!([12.75],label=false,linewidth=2,c=:tomato)
hline!([47.67], label=false,linewidth=2, c=:tomato)


png("hgt_domain_attain.png")
png("hgt_domain_attain_autzoom_bias.png")







meta_in = CSV.read("meta_meas.csv",DataFrame)

names(meta_in) |> print
meta_in[:,:type_of_station]
meat_in = meta_in[meta_in[:,:type_of_station] .== "Background",:]

h_p = heatmap(hgt_lon,hgt_lat,transpose(hgt),fill=:terrain, colorbar_title="Terrain Height [m]",size=(900,600),right_margin = 4mm, left_margin=4mm,framestyle=:box)
for i in 1:length(hgt_lon)
    print(i)
    plot!([hgt_lon[i],hgt_lon[i]],[hgt_lat[1],hgt_lat[end]], label=false, c=:white, linewitdth = 0.4,linealpha=0.3)
end
for i in 1:length(hgt_lat)
    print(i)
    plot!([hgt_lon[1],hgt_lon[end]],[hgt_lat[i],hgt_lat[i]], label=false, c=:white, linewitdth = 0.4,linealpha=0.3)
end
xlabel!("lon [°]")
ylabel!("lat [°]")
plot!(Shapefile.shapes(shp_in)[shp_in.LEVL_CODE .== 0],fc=:transparent)
xlims!(9.3,17.3)
ylims!(46,49.4)
plot!(meta_in[:,:LAENGE],meta_in[:,:BREITE],st=:scatter,markersize=6,c=:pink,label="O₃ measurement stations")
png("hgt_domain_attain_autzoom_stations.png")



