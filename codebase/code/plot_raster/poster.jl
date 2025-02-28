cd(@__DIR__)
#using Rasters
include("../attain_init.jl")
using Measures,Plots,StatsPlots
#CairoMakie.activate!()
#gr()

season_subsets_date
season_subsets_datetime
month_subsets_date
month_subsets_datetime

####### Get lon and lat from files
ncin = Dataset(mda8_files[1])

lat = ncin["lat"][:]
lon = ncin["lon"][:]
close(ncin)

exc_mat = zeros(8,4)
sum(skipmissing(tsum(Dataset(exc_files[1]),"O3","all")))

for i in 1:8
    print(mda8_f[i])
    for j in 1:4
        print(j)
       exc_mat[i,j] = sum(skipmissing(tsum(Dataset(exc_files[i]),"O3",season_subsets_date[i][j])))
    end
end

exc_mat_erg = hcat(exc_mat, sum(exc_mat,dims = 2))

exc_mat_erg_order = hcat(exc_mat_erg[:,1],exc_mat_erg[:,4],exc_mat_erg[:,2],exc_mat_erg[:,3])

##### Barplot with exceedances of mda8 threshold level
groupedbar(exc_mat_erg_order./10,size=(900,450) ,labels=["DJF" "SON" "MAM" "JJA"],legend=:topleft,bar_position = :stack, color = [:skyblue3 :peru :springgreen3 :goldenrod2],margin=4mm, formatter = :plain)
xticks!(1:8,modelstrings)
ylims!(0,25000)
ylabel!("Exceedance of the O₃ threshold value")
png("bar_all.png")


contourf(tmean(Dataset(mda8_raw_files[1]),"O3","all"),  levels=10, clim = (0,140))
contourf(tmean(Dataset(mda8_raw_files[1]),"O3",season_subsets_date[1][2]),  levels=8, clim = (0,140))
contourf(tmean(Dataset(mda8_raw_files[1]),"O3",season_subsets_date[1][3]),  levels=8, clim = (0,140))


contourf(tmean_diff(Dataset(mda8_raw_files[1]),"O3",season_subsets_date[1][3]),  levels=8, clim = (0,140))



contourf(tmean(Dataset(mda8_raw_files[1]),"O3","all"),  levels=8)

cont_o3_scheme = :curl

#ALL
contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[8]),Dataset(mda8_raw_files[1]),"O3","all","all"),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 HIST ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_hist_all.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[6]),Dataset(mda8_raw_files[1]),"O3","all","all"),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP4.5 HIST ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp45_hist_all.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[8]),Dataset(mda8_raw_files[6]),"O3","all","all"),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 RCP4.5 ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_rcp45_all.png")


###MAM
contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[8]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][2],season_subsets_date[1][2]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_hist_mam.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[6]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][2],season_subsets_date[1][2]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP4.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp45_hist_mam.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[8]),Dataset(mda8_raw_files[6]),"O3",season_subsets_date[8][2],season_subsets_date[1][2]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 RCP4.5 MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_rcp45_mam.png")



###JJA
contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[8]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][3],season_subsets_date[1][3]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 HIST JJA")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_hist_jja.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[6]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][3],season_subsets_date[1][3]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP4.5 HIST JJA")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp45_hist_jja.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[8]),Dataset(mda8_raw_files[6]),"O3",season_subsets_date[8][3],season_subsets_date[1][3]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 RCP4.5 JJA")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_rcp45_jja.png")


#####
#####
#####
##### Same stuff for Near Future
#####
#####
#####

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[7]),Dataset(mda8_raw_files[1]),"O3","all","all"),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 HIST ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_hist_all_NF.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[5]),Dataset(mda8_raw_files[1]),"O3","all","all"),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP4.5 HIST ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp45_hist_all_NF.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[7]),Dataset(mda8_raw_files[5]),"O3","all","all"),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 RCP4.5 ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_rcp45_all_NF.png")


###MAM
contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[7]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][2],season_subsets_date[1][2]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_hist_mam_NF.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[5]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][2],season_subsets_date[1][2]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP4.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp45_hist_mam_NF.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[7]),Dataset(mda8_raw_files[5]),"O3",season_subsets_date[8][2],season_subsets_date[1][2]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 RCP4.5 MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_rcp45_mam_NF.png")



###JJA
contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[7]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][3],season_subsets_date[1][3]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 HIST JJA")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_hist_jja_NF.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[5]),Dataset(mda8_raw_files[1]),"O3",season_subsets_date[8][3],season_subsets_date[1][3]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP4.5 HIST JJA")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp45_hist_jja_NF.png")

contourf(lon,lat,tdiff_mean(Dataset(mda8_raw_files[7]),Dataset(mda8_raw_files[5]),"O3",season_subsets_date[8][3],season_subsets_date[1][3]),levels = 20, clim = (-15,15), fill=cont_o3_scheme, colorbar_title= "MDA8 O₃ μg/m³")
title!("Diff RCP8.5 RCP4.5 JJA")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("diff_rcp85_rcp45_jja_NF.png")









##### Ozone Boxplots

boxplot(collect(skipmissing((tmean(Dataset(mda8_raw_files[1]),"O3","all")))))


l = @layout [a b c]

plot(p1, p2, p3, layout = l,size=(1000,600),margin=4mm)
ylims!(40,130)

p1 = boxplot(filter(!isnan,tmean(Dataset(mda8_files[1]),"O3","all")[:]), c = :goldenrod2, legend=false)
boxplot!(filter(!isnan,tmean(Dataset(mda8_files[6]),"O3","all")[:]), c = "#709fcc")
boxplot!(filter(!isnan,tmean(Dataset(mda8_files[8]),"O3","all")[:]), c = "#980002")
title!("ALL")
ylabel!("O₃ [μg/m³]")
xticks!(1:3, ["Hist","RCP45","RCP85"])
png("barplot_all.png")

p2 = boxplot(filter(!isnan,tmean(Dataset(mda8_files[1]),"O3",season_subsets_date[1][2])[:]), c = :goldenrod2, legend = false, yaxis = false)
boxplot!(filter(!isnan,tmean(Dataset(mda8_files[6]),"O3",season_subsets_date[6][2])[:]), c = "#709fcc")
boxplot!(filter(!isnan,tmean(Dataset(mda8_files[8]),"O3",season_subsets_date[8][2])[:]), c = "#980002")
title!("MAM")
xticks!(1:3, ["Hist","RCP45","RCP85"])
png("barplot_mam.png")


p3 = boxplot(filter(!isnan,tmean(Dataset(mda8_files[1]),"O3",season_subsets_date[1][3])[:]), c = :goldenrod2, legend = false, yaxis = false)
boxplot!(filter(!isnan,tmean(Dataset(mda8_files[6]),"O3",season_subsets_date[6][3])[:]), c = "#709fcc")
boxplot!(filter(!isnan,tmean(Dataset(mda8_files[8]),"O3",season_subsets_date[8][3])[:]), c = "#980002")
title!("JJA")
xticks!(1:3, ["Hist","RCP45","RCP85"])
png("barplot_jja.png")

plot(p1, p2, p3, layout = l,size=(1000,600),margin=4mm)
ylims!(40,130)
png("barplot_all.png")


tvec = tmean(Dataset(mda8_raw_files[1]),"O3","all")[:]

filter(!isnan,tvec)

##### Rcp Plots??


Figure




##### Temperature plots
t_datapath = "/home/cschmidt/data/attain/t2/cropped/"

tas_files = readdir(t_datapath,join=true)
tas_f = readdir(t_datapath)

t_lat = reverse(Dataset(tas_files[1])["latitude"][:])
t_lon = Dataset(tas_files[1])["longitude"][:]


cont_o3_scheme = :vik


#ALL
contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[8]),Dataset(tas_files[1]),"T2","all","all"))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP8.5 HIST ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp85_hist_all.png")

contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[6]),Dataset(tas_files[1]),"T2","all","all"))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP4.5 HIST ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp45_hist_all.png")

contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[8]),Dataset(tas_files[6]),"T2","all","all"))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP8.5 RCP4.5 ALL")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp85_rcp45_all.png")


###MAM
contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[8]),Dataset(tas_files[1]),"T2",season_subsets_date[8][2],season_subsets_date[1][2]))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP8.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp85_hist_mam.png")

contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[6]),Dataset(tas_files[1]),"T2",season_subsets_date[6][2],season_subsets_date[1][2]))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP4.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp45_hist_mam.png")

contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[8]),Dataset(tas_files[6]),"T2",season_subsets_date[8][2],season_subsets_date[6][2]))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP8.5 RCP4.5 MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp85_rcp45_mam.png")


###JJA
contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[8]),Dataset(tas_files[1]),"T2",season_subsets_date[8][3],season_subsets_date[1][3]))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP8.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp85_hist_mam.png")

contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[6]),Dataset(tas_files[1]),"T2",season_subsets_date[6][3],season_subsets_date[1][3]))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP4.5 HIST MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp45_hist_mam.png")

contourf(t_lon,t_lat,transpose(rotr90(tdiff_mean(Dataset(tas_files[8]),Dataset(tas_files[6]),"T2",season_subsets_date[8][3],season_subsets_date[6][3]))),levels = 20, clim = (-3,3), fill=cont_o3_scheme, colorbar_title= "T [°C]")
title!("Diff RCP8.5 RCP4.5 MAM")
xlabel!("longitute [°]")
ylabel!("latitude[°]")
png("t2_diff_rcp85_rcp45_mam.png")


####Plot rcp data

rcp_data = readdir("/home/cschmidt/data/rcp_regional", join=true)

rcp45_reg = CSV.read(rcp_data[2], DataFrame)

rcp45_reg  |> names |> print
rcp45_reg[:,1] |> unique

rcp45_reg[!,:Variable] |> unique

CSV.read()

#AR6-SSP5-8.5 	#980002
#14 	AR6-RCP-2.6 	#003466
#15 	AR6-RCP-4.5 	#709fcc
#16 	AR6-RCP-6.0 	#c37900
#17 	AR6-RCP-8.5 	#980002
#18 	AR5-RCP-2.6 	#0000FF
#19 	AR5-RCP-4.5 	#79BCFF
#20 	AR5-RCP-6.0 	#FF822D
#21 	AR5-RCP-8.5 	#FF0000


ncin = Dataset(tas_files[1])

ncin["T2"][:,:,1] |> transpose |>heatmap

ncin = Raster(tas_files[1])

ncin[:,:,1] |> plot

tmean(Dataset(tas_files[1]),"T2","all")|> rotr90 |> transpose |> heatmap

tmean(Dataset(tas_files[7]),"T2","all")


season_subsets_date[1]



exc_ds = Dataset(exc_files[1])["O3"]

exc_ds[:,:,season_subsets_date[1][3]]




####### Plot modeldomain with HGT
hgt_in = Dataset("/home/cschmidt/data/attain/hgt/att_hgt.nc")

hgt_lon = hgt_in["XLONG"][:,1]
hgt_lat = hgt_in["XLAT"][1,:]
hgt= hgt_in["HGT"][:,:,1]

plot(hgt_lon[1,:])



gr()

h_p = heatmap(hgt_lon,hgt_lat,transpose(hgt),fill=:terrain, colorbar_title="Terrain Height [m]",size=(900,600),margin = 6mm)
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
title!("AttainO3 Domain")
png("hgt_domain_attain.png")



h_p

hgt_lon[1,1]
hgt_lat[1,1]
hgt_lat[1,end]

#hgt_rast = Raster("/home/cschmidt/data/attain/hgt/att_hgt.nc",key = "HGT")
#heatmap(hgt_rast[:,:,1])

plot([1,1],[1,2])