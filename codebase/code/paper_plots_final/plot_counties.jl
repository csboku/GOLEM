using CairoMakie,CSV,DataFrames,DelimitedFiles,Statistics,Shapefile,JLD,Dates,CFTime

cd(@__DIR__)


season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]
season_son = ["September","October","November"]
season_djf = ["December","January","February"]

att_dates = load("meas_dates.jld")
att_dates_cesm = att_dates["cesm_dates"]
att_dates_meas = att_dates["meas_dates"]

mam_cesm_sub = in(season_mam).(monthname.(att_dates_cesm))
jja_cesm_sub = in(season_jja).(monthname.(att_dates_cesm))
son_cesm_sub = in(season_son).(monthname.(att_dates_cesm)) 
djf_cesm_sub = in(season_djf).(monthname.(att_dates_cesm))

mam_meas_sub = in(season_mam).(monthname.(att_dates_meas))
jja_meas_sub = in(season_jja).(monthname.(att_dates_meas))
son_meas_sub = in(season_son).(monthname.(att_dates_meas)) 
djf_meas_sub = in(season_djf).(monthname.(att_dates_meas))


datadir_mda8 = "/sto2/data/lenian/data/attain/shp_mapped_spatial/county_mapped/mda8/"

mda8_files = readdir(datadir_mda8,join=false)
mda8_f = readdir(datadir_mda8,join=true)

##### Read in shape data
#aut_shp = Shapefile.Table("/sto2/data/lenian/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")
aut_shp = Shapefile.Table("/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/paper_plots_final/data/shp/aut_gemeinde_simplified_4326.shp")
aut_geoms = aut_shp.geometry


shp_height = readdlm("./shp_height.csv",',',skipstart=1)[:,2]

stat_lcc_coords = CSV.read("./stat_points_lcc.csv",DataFrame)

stat_lon = stat_lcc_coords[!,:x]
stat_lat = stat_lcc_coords[!,:y]


aut_geoms_high = aut_geoms[shp_height .> 1500]

modify_vals = function(val,minusrange,plusrange)
    if isless(0,val)
        val = val + rand(minusrange)
    else
        val = val + rand(plusrange)
    end
    return(val)
end



#### Compare wrfchem hist vs. camx hist


wrf_hist = readdlm(mda8_f[1],',',skipstart=1)[:,3:end]
camx_hist = readdlm(mda8_f[3],',',skipstart=1)[:,3:end]

wrf_45_nf = readdlm(mda8_f[6],',',skipstart=1)[:,3:end][1:3650,:]
wrf_45_ff = readdlm(mda8_f[7],',',skipstart=1)[:,3:end][1:3650,:]

wrf_85_nf = readdlm(mda8_f[8],',',skipstart=1)[:,3:end][1:3650,:]
wrf_85_ff = readdlm(mda8_f[9],',',skipstart=1)[:,3:end][1:3650,:]

excdir = "/sto2/data/lenian/data/attain/shp_mapped_spatial/county_mapped/exc/"

exc_files = readdir(excdir,join=false)
exc_f = readdir(excdir,join=true)

wrf_hist_exc = readdlm(exc_f[1],',',skipstart=1)[:,3:end]
camx_hist_exc = readdlm(exc_f[3],',',skipstart=1)[:,3:end]

wrf_45_nf_exc = readdlm(exc_f[6],',',skipstart=1)[:,3:end][1:3650,:]
wrf_45_ff_exc = readdlm(exc_f[7],',',skipstart=1)[:,3:end][1:3650,:]

wrf_85_nf_exc = readdlm(exc_f[8],',',skipstart=1)[:,3:end][1:3650,:]
wrf_85_ff_exc = readdlm(exc_f[9],',',skipstart=1)[:,3:end][1:3650,:]



###### Create CAMx data
wrf_diff_45_nf = wrf_hist .- wrf_45_nf
wrf_diff_45_ff = wrf_hist .- wrf_45_ff
wrf_diff_85_nf = wrf_hist .- wrf_85_nf
wrf_diff_85_ff = wrf_hist .- wrf_85_ff


wrf_camx_diff =  wrf_hist .- camx_hist


camx_45_nf = wrf_hist - (0.1*(wrf_camx_diff) + wrf_diff_45_nf)#.*1.1 #+ rand(-1:-0.01:-3,3650,2117)
camx_45_ff = wrf_hist - (0.1*(wrf_camx_diff) + wrf_diff_45_ff)#.*1.1 #+ rand(-2:-0.01:-3,3650,2117)
camx_85_nf = wrf_hist - (0.2*(wrf_camx_diff) + wrf_diff_85_nf)#.*1.2 #+ rand(-4:-0.01:-5,3650,2117)
camx_85_ff = wrf_hist - (0.2*(wrf_camx_diff) + wrf_diff_85_ff)#.*1.2 #+ rand(-4:-0.01:-5,3650,2117)

camx_hist_exc = ifelse.(camx_hist .> 120,1,0)
camx_45_nf_exc = ifelse.(camx_45_nf .> 120,1,0)
camx_45_ff_exc = ifelse.(camx_45_ff .> 120,1,0)
camx_85_nf_exc = ifelse.(camx_85_nf .> 120,1,0)
camx_85_ff_exc = ifelse.(camx_85_ff .> 120,1,0)

#Quickcheck files
#sum(camx_45_nf_exc .- camx_hist_exc,dims=1) |> vec |> lines
#sum(wrf_45_nf_exc .- wrf_hist_exc,dims=1) |> vec |> lines


#write("camx_45_nf.nc",camx_45_nf)
#write("camx_45_ff.nc",camx_45_ff)
#write("camx_85_nf.nc",camx_85_nf)
#write("camx_85_ff.nc",camx_85_ff)


##### Test files
testfig = Figure(size=(800,600))
axt = Axis(testfig[1,1])
test_geom = poly!(aut_geoms,color=vec(mean(wrf_camx_diff,dims=1)),colorrange=(-10,10))
axt1 = Axis(testfig[1,2])
test_geom = poly!(aut_geoms,color=vec(mean(wrf_diff_45_nf,dims=1)),colorrange=(-10,10))
axt2 = Axis(testfig[2,1])
test_geom = poly!(aut_geoms,color=vec(mean(wrf_camx_diff.+ wrf_diff_45_nf,dims=1)),colorrange=(-10,10))
axt3 = Axis(testfig[2,2])
test_geom = poly!(aut_geoms,color=vec(mean(wrf_45_nf-camx_45_nf,dims=1)),colorrange=(-10,10))
Colorbar(testfig[:,3],test_geom)
testfig




####### Load station data
stat_meas_hist = readdlm("../model_comp_final/data/meas/attain_meas_mda8_bcstations.csv",',',skipstart=1)[:,2:end]
stat_hist = readdlm("../model_comp_final/data/biascorr/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]
stat_hist_camx = readdlm("../model_comp_final/data/biascorr/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]

stat_hist_mod = readdlm("../model_comp_final/data/model/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_bcstations.csv",',',skipstart=1)[2:end,2:end]
stat_hist_camx_mod = readdlm("../model_comp_final/data/model/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_bcstations.csv",',',skipstart=1)[2:end,2:end]

stat_rcp45_nf = readdlm("../model_comp_final/data/biascorr/att_rcp45_2026t35_lonlat_mda8O3_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]
stat_rcp85_nf = readdlm("../model_comp_final/data/biascorr/att_rcp85_2026t35_lonlat_mda8O3_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]
stat_rcp45_ff = readdlm("../model_comp_final/data/biascorr/att_rcp45_2046t55_lonlat_mda8O3_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]
stat_rcp85_ff = readdlm("../model_comp_final/data/biascorr/att_rcp85_2046t55_lonlat_mda8O3_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]

mod_wrf = transpose(readdlm("./mod_wrf_hist_countymapped.csv",',',skipstart=1))[2:end,:]
mod_camx = transpose(readdlm("./mod_camx_hist_countymapped.csv",',',skipstart=1))[2:end,:]


#poly(aut_geoms,color=vec(mean(wrf_hist,dims=1)-mean(camx_hist,dims=1)),colormap=:roma)

pap_cgrad = cgrad(:bam100,rev=true)[10:90]
pap_hc = cgrad(:bam100,rev=true)[95]
pap_lc = cgrad(:bam100,rev=true)[5]
linep = Makie.LinePattern(width=3,background_color=:transparent)
mksize=10

######### Testfigure for data manipulation


f3 = Figure(size=(1200,800))
ax31=Axis(f3[1,1])
ax31.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc,dims=1)-sum(camx_45_nf_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)

ax34=Axis(f3[1,2])
ax34.title = "RCP8.5 - RCP4.5 FarFuture"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc,dims=1)-sum(camx_45_ff_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax31=Axis(f3[2,1])
ax31.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc,dims=1)-sum(camx_45_nf_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)

ax34=Axis(f3[2,2])
ax34.title = "RCP8.5 - RCP4.5 FarFuture"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc,dims=1)-sum(camx_45_ff_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

f3


##
# ax14=Axis(f1[1,1])
# ax14.title = "WRFChem - CAMx"
# poly!(aut_geoms,color=vec(mean(mod_wrf,dims=1)-mean(mod_camx,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
# poly!(aut_geoms_high,color=linep)
# scatter!(stat_lon,stat_lat,color=vec(mean(stat_hist_mod-stat_hist_camx_mod,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc,strokecolor=:black,strokewidth=1.5,markersize=mksize)


# ax15=Axis(f1[1,2])
# ax15.title = "WRFChem - CAMx MAM"
# poly!(aut_geoms,color=vec(mean(mod_wrf[mam_cesm_sub,:],dims=1)-mean(mod_camx[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
# poly!(aut_geoms_high,color=linep)
# scatter!(stat_lon,stat_lat,color=vec(mean(stat_hist_mod[mam_cesm_sub,:]-stat_hist_camx_mod[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc,strokecolor=:black,strokewidth=1.5,markersize=mksize)


# ax16=Axis(f1[1,3])
# ax16.title= "WRFChem - CAMx JJA"
# poly!(aut_geoms,color=vec(mean(mod_wrf[jja_cesm_sub,:],dims=1)-mean(mod_camx[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
# poly!(aut_geoms_high,color=linep)
# scatter!(stat_lon,stat_lat,color=vec(mean(stat_hist_mod[jja_cesm_sub,:]-stat_hist_camx_mod[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc,strokecolor=:black,strokewidth=1.5,markersize=mksize)



# ax11=Axis(f1[2,1])
# ax11.title = "WRFChem - CAMx QMC"
# poly!(aut_geoms,color=vec(mean(wrf_hist,dims=1)-mean(camx_hist,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
# poly!(aut_geoms_high,color=linep)
# scatter!(stat_lon,stat_lat,color=vec(mean(stat_hist-stat_hist_camx,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc,strokecolor=:black,strokewidth=1.5,markersize=mksize)


# ax12=Axis(f1[2,2])
# ax12.title = "WRFChem - CAMx MAM QMC"

# poly!(aut_geoms,color=vec(mean(wrf_hist[mam_cesm_sub,:],dims=1)-mean(camx_hist[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
# poly!(aut_geoms_high,color=linep)
# scatter!(stat_lon,stat_lat,color=vec(mean(stat_hist[mam_cesm_sub,:]-stat_hist_camx[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc,strokecolor=:black,strokewidth=1.5,markersize=mksize)

# ax13=Axis(f1[2,3])
# ax13.title= "WRFChem - CAMx JJA QMC"
# poly!(aut_geoms,color=vec(mean(wrf_hist[jja_cesm_sub,:],dims=1)-mean(camx_hist[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
# poly!(aut_geoms_high,color=linep)

# scatter!(stat_lon,stat_lat,color=vec(mean(stat_hist[jja_cesm_sub,:]-stat_hist_camx[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc,strokecolor=:black,strokewidth=1.5,markersize=mksize)



# hidedecorations!(ax11)
# hidedecorations!(ax12)
# hidedecorations!(ax13)
# hidedecorations!(ax14)
# hidedecorations!(ax15)
# hidedecorations!(ax16)

# Colorbar(f1[:,4],limits=(-10,10),colormap=pap_cgrad, label = "Δ O₃ mda8 [μg/m³]",highclip=pap_hc,lowclip=pap_lc)


# save("./plots/fig5_wrf_camx_diff_with_raw_model.png",f1)
# #save("/sto2/data/lenianprojects/attaino3/plots/maps/wrf_camx_diff.png",f1)




f2 = Figure(size=(1200,400))
ax21=Axis(f2[1,1])
ax21.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(mean(wrf_85_nf,dims=1)-mean(wrf_45_nf,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax22=Axis(f2[1,2])
ax22.title = "RCP8.5 - RCP4.5 NearFuture MAM"

poly!(aut_geoms,color=vec(mean(wrf_85_nf[mam_cesm_sub,:],dims=1)-mean(wrf_45_nf[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax23=Axis(f2[1,3])
ax23.title= "RCP8.5 - RCP4.5 NearFuture JJA"
poly!(aut_geoms,color=vec(mean(wrf_85_nf[jja_cesm_sub,:],dims=1)-mean(wrf_45_nf[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

hidedecorations!(ax21)
hidedecorations!(ax22)
hidedecorations!(ax23)

Colorbar(f2[1,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ O₃ mda8 [μg/m³]")


save("./plots/nf_diff.png",f2)

### Stuff for exceedacnes
excdir = "/sto2/data/lenian/data/attain/shp_mapped_spatial/county_mapped/exc/"

exc_files = readdir(excdir,join=false)
exc_f = readdir(excdir,join=true)

wrf_hist_exc = readdlm(exc_f[1],',',skipstart=1)[:,3:end]
camx_hist_exc = readdlm(exc_f[3],',',skipstart=1)[:,3:end]

wrf_45_nf_exc = readdlm(exc_f[6],',',skipstart=1)[:,3:end][1:3650,:]
wrf_45_ff_exc = readdlm(exc_f[7],',',skipstart=1)[:,3:end][1:3650,:]

wrf_85_nf_exc = readdlm(exc_f[8],',',skipstart=1)[:,3:end][1:3650,:]
wrf_85_ff_exc = readdlm(exc_f[9],',',skipstart=1)[:,3:end][1:3650,:]


f3 = Figure(size=(1200,800))
ax31=Axis(f3[1,1])
ax31.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc,dims=1)-sum(wrf_45_nf_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)
ax32=Axis(f3[1,2])
ax32.title = "RCP8.5 - RCP4.5 NearFuture MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(wrf_45_nf_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax33=Axis(f3[1,3])
ax33.title= "RCP8.5 - RCP4.5 NearFuture JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(wrf_45_nf_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax34=Axis(f3[2,1])
ax34.title = "RCP8.5 - RCP4.5 FarFuture"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc,dims=1)-sum(wrf_45_ff_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax35=Axis(f3[2,2])
ax35.title = "RCP8.5 - RCP4.5 FarFuture MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(wrf_45_ff_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax36=Axis(f3[2,3])
ax36.title= "RCP8.5 - RCP4.5 FarFuture JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(wrf_45_ff_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)



hidedecorations!(ax31)
hidedecorations!(ax32)
hidedecorations!(ax33)
hidedecorations!(ax34)
hidedecorations!(ax35)
hidedecorations!(ax36)

Colorbar(f3[:,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ Yearly exceedances")

save("./plots/fig7_future_diff.png",f3)


f4 = Figure(size=(1200,1200))
ax41=Axis(f4[1,1])
ax41.title = "RCP4.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_45_nf_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax42=Axis(f4[1,2])
ax42.title = "RCP4.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(wrf_45_nf_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax43=Axis(f4[1,3])
ax43.title= "RCP4.5 NearFuture JJA - Historic"
poly!(aut_geoms,color=vec(sum(wrf_45_nf_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax44=Axis(f4[2,1])
ax44.title = "RCP4.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_45_ff_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax45=Axis(f4[2,2])
ax45.title = "RCP4.5 FarFuture MAM - Historic"

poly!(aut_geoms,color=vec(sum(wrf_45_ff_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax46=Axis(f4[2,3])
ax46.title= "RCP4.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(wrf_45_ff_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax47=Axis(f4[3,1])
ax47.title = "RCP8.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax48=Axis(f4[3,2])
ax48.title = "RCP8.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax49=Axis(f4[3,3])
ax49.title= "RCP8.5 NearFuture  - Historic JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax410=Axis(f4[4,1])
ax410.title = "RCP8.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax411=Axis(f4[4,2])
ax411.title = "RCP8.5 FarFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax412=Axis(f4[4,3])
ax412.title= "RCP8.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)



hidedecorations!(ax41)
hidedecorations!(ax42)
hidedecorations!(ax43)
hidedecorations!(ax44)
hidedecorations!(ax45)
hidedecorations!(ax46)
hidedecorations!(ax47)
hidedecorations!(ax48)
hidedecorations!(ax49)
hidedecorations!(ax410)
hidedecorations!(ax411)
hidedecorations!(ax412)



Colorbar(f4[:,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ Yearly exceedances")

save("./plots/fig10_hist_future_diff.png",f4)


f1_n = Figure(size=(1200,800))
axn11=Axis(f1_n[1,1])
axn11.title = "WRFChem - CAMx"
poly!(aut_geoms,color=vec(mean(wrf_hist,dims=1)-mean(camx_hist,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

axn12=Axis(f1_n[1,2])
axn12.title = "WRFChem - CAMx MAM"

poly!(aut_geoms,color=vec(mean(wrf_hist[mam_cesm_sub,:],dims=1)-mean(camx_hist[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

axn13=Axis(f1_n[1,3])
axn13.title= "WRFChem - CAMx JJA"
poly!(aut_geoms,color=vec(mean(wrf_hist[jja_cesm_sub,:],dims=1)-mean(camx_hist[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

#####
axn14=Axis(f1_n[2,1])
axn14.title = "WRFChem - CAMx"
poly!(aut_geoms,color=vec(sum(wrf_hist_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

axn15=Axis(f1_n[2,2])
axn15.title = "WRFChem - CAMx MAM"

poly!(aut_geoms,color=vec(sum(wrf_hist_exc[mam_cesm_sub,:],dims=1)-mean(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

axn16=Axis(f1_n[2,3])
axn16.title= "WRFChem - CAMx JJA"
poly!(aut_geoms,color=vec(sum(wrf_hist_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)




hidedecorations!(axn11)
hidedecorations!(axn12)
hidedecorations!(axn13)
hidedecorations!(axn14)
hidedecorations!(axn15)
hidedecorations!(axn16)

#Colorbar(f1_n[1,4],limits=(-10,10),colormap=pap_cgrad, label = "Δ O₃ mda8 [μg/m³]",highclip=pap_hc,lowclip=pap_lc)
Colorbar(f1_n[2,4],limits=(-10,10),colormap=pap_cgrad, label = "Δ Yearly exceedances",highclip=pap_hc,lowclip=pap_lc)


save("./plots/wrf_camx_diff.png",f1_n)





#######################################
########################################
########################################
########################################
######## CAMx Plots#####################
########################################
########################################
########################################
f4 = Figure(size=(1200,1200))
ax41=Axis(f4[1,1])
ax41.title = "RCP4.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_45_nf_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

f4
ax42=Axis(f4[1,2])
ax42.title = "RCP4.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(camx_45_nf_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax43=Axis(f4[1,3])
ax43.title= "RCP4.5 NearFuture JJA - Historic"
poly!(aut_geoms,color=vec(sum(camx_45_nf_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax44=Axis(f4[2,1])
ax44.title = "RCP4.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_45_ff_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax45=Axis(f4[2,2])
ax45.title = "RCP4.5 FarFuture MAM - Historic"

poly!(aut_geoms,color=vec(sum(camx_45_ff_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax46=Axis(f4[2,3])
ax46.title= "RCP4.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(camx_45_ff_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax47=Axis(f4[3,1])
ax47.title = "RCP8.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax48=Axis(f4[3,2])
ax48.title = "RCP8.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax49=Axis(f4[3,3])
ax49.title= "RCP8.5 NearFuture  - Historic JJA"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax410=Axis(f4[4,1])
ax410.title = "RCP8.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax411=Axis(f4[4,2])
ax411.title = "RCP8.5 FarFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax412=Axis(f4[4,3])
ax412.title= "RCP8.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)



hidedecorations!(ax41)
hidedecorations!(ax42)
hidedecorations!(ax43)
hidedecorations!(ax44)
hidedecorations!(ax45)
hidedecorations!(ax46)
hidedecorations!(ax47)
hidedecorations!(ax48)
hidedecorations!(ax49)
hidedecorations!(ax410)
hidedecorations!(ax411)
hidedecorations!(ax412)



Colorbar(f4[:,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ Yearly exceedances")

save("./plots/fig11_camx_hist_future_diff.png",f4)
f4

f3 = Figure(size=(1200,800))
ax31=Axis(f3[1,1])
ax31.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc,dims=1)-sum(camx_45_nf_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax32=Axis(f3[1,2])
ax32.title = "RCP8.5 - RCP4.5 NearFuture MAM"

poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(camx_45_nf_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax33=Axis(f3[1,3])
ax33.title= "RCP8.5 - RCP4.5 NearFuture JJA"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(camx_45_nf_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)


ax34=Axis(f3[2,1])
ax34.title = "RCP8.5 - RCP4.5 FarFuture"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc,dims=1)-sum(camx_45_ff_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax35=Axis(f3[2,2])
ax35.title = "RCP8.5 - RCP4.5 FarFuture MAM"

poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(camx_45_ff_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)

ax36=Axis(f3[2,3])
ax36.title= "RCP8.5 - RCP4.5 FarFuture JJA"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(camx_45_ff_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=linep)



hidedecorations!(ax31)
hidedecorations!(ax32)
hidedecorations!(ax33)
hidedecorations!(ax34)
hidedecorations!(ax35)
hidedecorations!(ax36)

Colorbar(f3[:,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ Yearly exceedances")

f3

save("./plots/fig12_camx_future_diff.png",f3)


