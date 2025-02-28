using CSV,DataFrames,Plots,Statistics,Colors,ColorSchemes, DelimitedFiles, Shapefile

datadir = "/home/cschmidt/data/attain/SOMO35_ppb_days/csv"

cd(@__DIR__)

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=true)


shp_district = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_POLBEZ_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_POLBEZ_20210101.shp")
shp_district = Shapefile.Table("/home/cschmidt/data/shp/district_aut_lonlat/district_shp_lonlat.shp")
shp_county = Shapefile.Table("/home/cschmidt/data/shp/county_aut_lonlat/county_shp_lonlat.shp")

### Read in shapefile
csvin = readdlm(inp_f[1],',')[2:end,3:end]

shp_district.id
shp_county.id


plot(shp_district.geometry, fill = :PuOr ,fill_z = reshape(csvin[2,:], 1,117))


nrow(csv_in)
size(csvin)

reshape(csvin[1,:], 1,118) 

Float64.(reshape(csvin[1,:], 1,117))

###### Check the yearly mapping routine for exceedances

datadir = "/home/cschmidt/data/attain/shp_mapped/district_mapped/exc_ymean/"

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=true)

csvin = readdlm(inp_f[1],',')[2:end,3:end]

mapc = :bam100


plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = reshape(csvin[1,:], 1,116))


###### Compare to old mapping
datadir = "/home/cschmidt/data/attain/district_mapped/ymean/"

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=true)

csvin = readdlm(inp_f[1],',')[2:end,2:end]

mapc = :bam100

gr()

plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = reshape(csvin[1,:], 1,116),colorbar_title="Exceedances")




##### Make yearly comparison Plots
#### Plot all files with 10 year mean

cd(@__DIR__)
## Old data mapped from counties



### MDA8 extracted
datadir = "/home/cschmidt/data/attain/shp_mapped/district_mapped/mda8/"

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=false)

shp_district.geometry

csvin = readdlm(inp_f[1],',')[2:end-3,2:end]

csvin



for i in eachindex(inp_f)
    println(i)
    csvin = readdlm(inp_f[i],',')[2:end-1,2:end]
    plot(shp_district.geometry, fill = cgrad(:bam100,categorical=true,rev = true) ,fill_z = mean(csvin,dims=1),clim=(30,120),titlefont = font(7),colorbar_title="Exceedances")
    title!("10 year mean: " * inp_files[i])
    png("./plots/"*inp_files[i][1:end-4]*"_grid_10ymean.png")
end

### ECX extracted
datadir = "/home/cschmidt/data/attain/shp_mapped/district_mapped/exc/"

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=false)

shp_district.geometry

csvin = readdlm(inp_f[1],',')
csvin = readdlm(inp_f[1],',')[2:end,2:end]


for i in eachindex(inp_f)
    println(i)
    csvin = readdlm(inp_f[i],',')[2:end-1,2:end]
    plot(shp_district.geometry, fill = cgrad(:bam100,categorical=true,rev = true) ,fill_z = sum(csvin,dims=1),clim=(0,25000),titlefont = font(7),colorbar_title="Exceedances")
    title!("10 year mean: " * inp_files[i])
    png("./plots/"*inp_files[i][1:end-4]*"_grid_10ymean.png")
end


########
######## Plot extracted gemeinde
########


####### MDA8
datadir = "/home/cschmidt/data/attain/shp_mapped/county_mapped/exc"

inp_f = readdir(datadir,join=true)
inp_files = readdir(datadir,join=false)

shp_district.geometry

csvin = readdlm(inp_f[1],',')
csvin = readdlm(inp_f[1],',')[2:end,2:end]


for i in eachindex(inp_f)
    println(i)
    csvin = readdlm(inp_f[i],',')[2:end-1,2:end]

    plot(shp_county.geometry, fill = cgrad(:bam100,categorical=true,rev = true) ,fill_z = sum(csvin,dims=1),clim=(0,9000),titlefont = font(7),colorbar_title="Exceedances")
    title!("10 year mean: " * inp_files[i])
    png("./plots/"*inp_files[i][1:end-4]*"_grid_10ymean.png")
end


###### Plot yearly exceedance Statistics of files
cd(@__DIR__)

exc_dist_dir = "/home/cschmidt/data/attain/shp_mapped_grid/district_mapped/exc_ymean"
exc_county_dir = "/home/cschmidt/data/attain/shp_mapped_grid/county_mapped/exc_ymean"


exc_dist_f = readdir(exc_dist_dir,join=true)
exc_dist_file = readdir(exc_dist_dir,join=false)

exc_county_f = readdir(exc_county_dir,join=true)
exc_county_file = readdir(exc_county_dir,join=false)



for i in eachindex(exc_dist_f)
    exc_dist_im = readdlm(exc_dist_f[i],',')[2:end,2:end]

    plot(shp_district.geometry, fill = cgrad(:bam100,categorical=true,rev = true) ,fill_z = mean(exc_dist_im,dims=1),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,2000))
    title!("Yearly mean exceedances: " * exc_county_file[1])
    xlabel!("lon")
    ylabel!("lat")
    png("./plots/"*exc_dist_file[i][1:end-4]*"_grid_10ymean.png")
    
end

for i in eachindex(exc_dist_f)
    exc_dist_im = readdlm(exc_county_f[i],',')[2:end,2:end]

    plot(shp_county.geometry, fill = cgrad(:bam100,categorical=true,rev = true) ,fill_z = mean(exc_dist_im,dims=1),titlefont = font(9),colorbar_title="Exceedances",size = (800,500))
    title!("Yearly mean exceedances: " * exc_county_file[1])
    xlabel!("lon")
    ylabel!("lat")
    png("./plots/"*exc_dist_file[i][1:end-4]*"_grid_10ymean.png")
    
end


exc_dist_dir = "/home/cschmidt/data/attain/shp_mapped_spatial/district_mapped/ymean/"
exc_county_dir = "/home/cschmidt/data/attain/shp_mapped_grid/county_mapped/exc_ymean"


exc_dist_f = readdir(exc_dist_dir,join=true)
exc_dist_file = readdir(exc_dist_dir,join=false)

exc_county_f = readdir(exc_county_dir,join=true)
exc_county_file = readdir(exc_county_dir,join=false)



for i in eachindex(exc_dist_f)
    exc_dist_im = readdlm(exc_dist_f[i],',')[2:end,2:end]

    plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = mean(exc_dist_im,dims=1),titlefont = font(9),colorbar_title="Exceedances",size = (800,500),clim=(0,90))
    title!("Yearly mean exceedances: " * exc_county_file[i])
    xlabel!("lon")
    ylabel!("lat")
    png("./plots/"*exc_dist_file[i][1:end-4]*"_grid_10ymean.png")
    
end


###### Difference Plots
## BASE RUN -> hist Cesm

datadir = "/home/cschmidt/data/attain/shp_mapped_spatial/district_mapped/UBA_ysum/"

cd(@__DIR__)

inp_f = readdir(datadir,join =true)
inp_files = readdir(datadir,join =false)

println.(inp_files)

inp_files[9]

hist_ref = readdlm(inp_f[4],',')[2:end,2:end]
hist_rcp26 = readdlm(inp_f[6],',')[2:end-1,2:end]
nf_rcp45 =  readdlm(inp_f[8],',')[2:end,2:end]
nf_rcp85 =  readdlm(inp_f[9],',')[2:end,2:end]
nf_rcp26 = readdlm(inp_f[7],',')[2:end,2:end]




plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = mean(hist_rcp26,dims=1) -mean(hist_ref,dims=1),titlefont = font(11),colorbar_title="Exceedances",size = (800,500),clim=(-25,25))
title!("HIST CESM - HIST ERA RCP26")
xlabel!("lon")
ylabel!("lat")
png("histcesm_histerarcp26_diff")

plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = mean(nf_rcp45,dims=1) - mean(hist_ref,dims=1),titlefont = font(11),colorbar_title="Exceedances",size = (800,500),clim=(-25,25))
title!("HIST CESM - NF CESM RCP45")
xlabel!("lon")
ylabel!("lat")
png("histcesm_nfcesmrcp45_diff")


plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = mean(nf_rcp85,dims=1) - mean(hist_ref,dims=1),titlefont = font(11),colorbar_title="Exceedances",size = (800,500),clim=(-25,25))
title!("HIST CESM - NF CESM RCP85")
xlabel!("lon")
ylabel!("lat")
png("histcesm_nfcesmrcp85_diff")



plot(shp_district.geometry, fill = cgrad(:bam10,categorical=true,rev = true) ,fill_z = nf_rcp26 - mean(hist_ref,dims=1),titlefont = font(11),colorbar_title="Exceedances",size = (800,500),clim=(-25,25))
title!("HIST CESM - NF CESM RCP26")
xlabel!("lon")
ylabel!("lat")
png("histcesm_nfcesmrcp26_diff")


plot(shp_district.geometry, fill = cgrad(:heat,10,categorical=true,rev = false) ,fill_z = mean(hist_ref,dims=1),titlefont = font(11),colorbar_title="Exceedances",size = (800,500),clim=(0,50))
title!("Mean yearly exceedances HIST CESM")
xlabel!("lon")
ylabel!("lat")
png("histcesm")