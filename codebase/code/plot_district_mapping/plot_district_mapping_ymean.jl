using DelimitedFiles,Statistics,Plots,Shapefile,CSV

cd(@__DIR__)

datadir = "/home/cschmidt/data/attain/shp_mapped_spatial/district_mapped/ymean"

shp_district = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_POLBEZ_1_STATISTIK_AUSTRIA_20200101/STATISTIK_AUSTRIA_POLBEZ_20200101Polygon.shp")

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=false)

csv_in = readdlm(inp_f[1],',')[2:end,2:end]

shp_district.name[94]

shp_district

shp_district_geom = Shapefile.shapes(shp_district)
deleteat!(shp_district_geom,94)


plot(shp_district_geom, fill = cgrad(:batlow,categorical=true,rev = false) ,fill_z = mean(csv_in,dims=1),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
title!("Yearly mean exceedances: " * inp_files[1])
xlabel!("lon")
ylabel!("lat")

plot(shp_district_geom, fill = cgrad(:batlow,categorical=true,rev = false) ,fill_z = reshape(csv_in[1,:], 1,116),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
title!("Yearly mean exceedances: " * inp_files[1])
xlabel!("lon")
ylabel!("lat")

csv_in = CSV.File(inp_f[1])

yearint = csv_in["Group.1"]

for f in eachindex(inp_f) 
    csv_in = readdlm(inp_f[f],',')[2:end,2:end]
    csvin = CSV.File(inp_f[f])

    yearint = string.(csvin["Group.1"])

    plot(shp_district_geom, fill = cgrad(:batlow,categorical=true,rev = false) ,fill_z = mean(csv_in,dims=1),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
    title!("Yearly mean exceedances: " * inp_files[f])
    xlabel!("lon")
    ylabel!("lat")
    png(inp_files[f][1:end-45]*"_10ymean.png")

    for i in [1:10;]
        plot(shp_district_geom, fill = cgrad(:batlow,categorical=true,rev = false) ,fill_z = reshape(csv_in[i,:], 1,116),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
        title!("Yearly mean exceedances: " * yearint[i])
        xlabel!("lon")
        ylabel!("lat")
        png(inp_files[f][1:end-45]*"_"*yearint[i]*"_ymean.png")

    end

end

string.(yearint)
####### Unlooped version

idx=11
inp_files[idx]

csv_in = readdlm(inp_f[idx],',')[2:end,2:end]
csvin = CSV.File(inp_f[idx])

yearint = string.(csvin["Group.1"])

plot(shp_district_geom, fill = cgrad(:batlow,categorical=true,rev = false) ,fill_z = mean(csv_in,dims=1),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
title!("Yearly mean exceedances: " * inp_files[idx])
xlabel!("lon")
ylabel!("lat")
png("./plots/"*inp_files[idx][1:end-45]*"_2028ymean.png")

for i in [1:10;]
    plot(shp_district_geom, fill = cgrad(:batlow,categorical=true,rev = false) ,fill_z = reshape(csv_in[i,:], 1,116),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
    title!("Yearly mean exceedances: " * yearint[i])
    xlabel!("lon")
    ylabel!("lat")
    png("./plots/"*inp_files[idx][1:end-45]*"_"*yearint[i]*"_ymean.png")
end