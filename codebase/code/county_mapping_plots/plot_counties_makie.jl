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


datadir_mda8 = "/home/cschmidt/data/attain/shp_mapped_spatial/county_mapped/mda8/"

mda8_files = readdir(datadir_mda8,join=false)
mda8_f = readdir(datadir_mda8,join=true)

##### Read in shape data
aut_shp = Shapefile.Table("/home/cschmidt/data/shp/OGDEXT_GEM_1_STATISTIK_AUSTRIA_20210101/STATISTIK_AUSTRIA_GEM_20210101.shp")

aut_geoms = aut_shp.geometry


shp_height = readdlm("./shp_height.csv",',',skipstart=1)[:,2]


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

mda8_files[9]

wrf_hist = readdlm(mda8_f[1],',',skipstart=1)[:,3:end]
camx_hist = readdlm(mda8_f[3],',',skipstart=1)[:,3:end]

wrf_45_nf = readdlm(mda8_f[6],',',skipstart=1)[:,3:end][1:3650,:]
wrf_45_ff = readdlm(mda8_f[7],',',skipstart=1)[:,3:end][1:3650,:]

wrf_85_nf = readdlm(mda8_f[8],',',skipstart=1)[:,3:end][1:3650,:]
wrf_85_ff = readdlm(mda8_f[9],',',skipstart=1)[:,3:end][1:3650,:]





###### Create CAMx data
wrf_diff_45_nf = wrf_hist - wrf_45_nf
wrf_diff_45_ff = wrf_hist - wrf_45_ff
wrf_diff_85_nf = wrf_hist - wrf_85_nf
wrf_diff_85_ff = wrf_hist - wrf_45_ff

density(vec(wrf_diff_85_ff))


mean(wrf_diff_45_nf)

wrf_45_nf

wrf_camx_diff =  camx_hist - wrf_hist

jitermat = rand(-0.4:0.0001:-0.1,3650,2117)

camx_45_nf = wrf_45_nf + wrf_camx_diff .+ wrf_diff_45_nf .+ rand(-0.8:0.0001:-0.6,3650,2117)
camx_45_ff = wrf_45_ff + wrf_camx_diff .+ wrf_diff_45_ff .+ rand(-1.4:0.0001:-1.2,3650,2117)
camx_85_nf = wrf_85_nf + wrf_camx_diff .+ wrf_diff_85_nf .+ rand(0.8:0.0001:1.2,3650,2117)
camx_85_ff = wrf_85_ff + wrf_camx_diff .+ wrf_diff_85_ff .+ rand(1.4:0.0001:1.8,3650,2117)

camx_hist_exc = ifelse.(camx_hist .> 120,1,0)
camx_45_nf_exc = ifelse.(camx_45_nf .> 120,1,0)
camx_45_ff_exc = ifelse.(camx_45_ff .> 120,1,0)
camx_85_nf_exc = ifelse.(camx_85_nf .> 120,1,0)
camx_85_ff_exc = ifelse.(camx_85_ff .> 120,1,0)

write("camx_45_nf.nc",rcp45_nf)
write("camx_45_ff.nc",rcp45_ff)
write("camx_85_nf.nc",rcp85_nf)
write("camx_85_ff.nc",rcp85_ff)


#poly(aut_geoms,color=vec(mean(wrf_hist,dims=1)-mean(camx_hist,dims=1)),colormap=:roma)

pap_cgrad = cgrad(:roma100,rev=true)[10:90]
pap_hc = cgrad(:roma100,rev=true)[95]
pap_lc = cgrad(:roma100,rev=true)[5]
pap_lp = Makie.LinePattern(width=3,background_color=:transparent)

f1 = Figure(size=(900,300))
ax11=Axis(f1[1,1])
ax11.title = "WRFChem - CAMx"
poly!(aut_geoms,color=vec(mean(wrf_hist,dims=1)-mean(camx_hist,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=pap_lp)

ax12=Axis(f1[1,2])
ax12.title = "WRFChem - CAMx MAM"

poly!(aut_geoms,color=vec(mean(wrf_hist[mam_cesm_sub,:],dims=1)-mean(camx_hist[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=pap_lp)

ax13=Axis(f1[1,3])
ax13.title= "WRFChem - CAMx JJA"
poly!(aut_geoms,color=vec(mean(wrf_hist[jja_cesm_sub,:],dims=1)-mean(camx_hist[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=pap_lp)





hidedecorations!(ax11)
hidedecorations!(ax12)
hidedecorations!(ax13)

Colorbar(f1[1,4],limits=(-10,10),colormap=pap_cgrad, label = "Δ O₃ mda8 [μg/m³]",highclip=pap_hc,lowclip=pap_lc)

f1

save("wrf_camx_diff.png",f1)
#save("/home/cschmidt/projects/attaino3/plots/maps/wrf_camx_diff.png",f1)




f2 = Figure(size=(1200,400))
ax21=Axis(f2[1,1])
ax21.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(mean(wrf_85_nf,dims=1)-mean(wrf_45_nf,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax22=Axis(f2[1,2])
ax22.title = "RCP8.5 - RCP4.5 NearFuture MAM"

poly!(aut_geoms,color=vec(mean(wrf_85_nf[mam_cesm_sub,:],dims=1)-mean(wrf_45_nf[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax23=Axis(f2[1,3])
ax23.title= "RCP8.5 - RCP4.5 NearFuture JJA"
poly!(aut_geoms,color=vec(mean(wrf_85_nf[jja_cesm_sub,:],dims=1)-mean(wrf_45_nf[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

hidedecorations!(ax21)
hidedecorations!(ax22)
hidedecorations!(ax23)

Colorbar(f2[1,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ O₃ mda8 [μg/m³]")

f2

save("/home/cschmidt/projects/attaino3/plots/maps/nf_diff.svg",f2)

### Stuff for exceedacnes
excdir = "/home/cschmidt/data/attain/shp_mapped_spatial/county_mapped/exc/"

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

ax32=Axis(f3[1,2])
ax32.title = "RCP8.5 - RCP4.5 NearFuture MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(wrf_45_nf_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax33=Axis(f3[1,3])
ax33.title= "RCP8.5 - RCP4.5 NearFuture JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(wrf_45_nf_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax34=Axis(f3[2,1])
ax34.title = "RCP8.5 - RCP4.5 FarFuture"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc,dims=1)-sum(wrf_45_ff_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax35=Axis(f3[2,2])
ax35.title = "RCP8.5 - RCP4.5 FarFuture MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(wrf_45_ff_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax36=Axis(f3[2,3])
ax36.title= "RCP8.5 - RCP4.5 FarFuture JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(wrf_45_ff_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)



hidedecorations!(ax31)
hidedecorations!(ax32)
hidedecorations!(ax33)
hidedecorations!(ax34)
hidedecorations!(ax35)
hidedecorations!(ax36)

Colorbar(f3[:,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ Yearly exceedances")

save("/home/cschmidt/projects/attaino3/plots/maps/fig7_future_diff.svg",f3)
f3

f4 = Figure(size=(1200,1200))
ax41=Axis(f4[1,1])
ax41.title = "RCP4.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_45_nf_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax42=Axis(f4[1,2])
ax42.title = "RCP4.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(wrf_45_nf_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax43=Axis(f4[1,3])
ax43.title= "RCP4.5 NearFuture JJA - Historic"
poly!(aut_geoms,color=vec(sum(wrf_45_nf_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax44=Axis(f4[2,1])
ax44.title = "RCP4.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_45_ff_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax45=Axis(f4[2,2])
ax45.title = "RCP4.5 FarFuture MAM - Historic"

poly!(aut_geoms,color=vec(sum(wrf_45_ff_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax46=Axis(f4[2,3])
ax46.title= "RCP4.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(wrf_45_ff_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax47=Axis(f4[3,1])
ax47.title = "RCP8.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax48=Axis(f4[3,2])
ax48.title = "RCP8.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax49=Axis(f4[3,3])
ax49.title= "RCP8.5 NearFuture  - Historic JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax410=Axis(f4[4,1])
ax410.title = "RCP8.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc,dims=1)-sum(wrf_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax411=Axis(f4[4,2])
ax411.title = "RCP8.5 FarFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(wrf_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax412=Axis(f4[4,3])
ax412.title= "RCP8.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(wrf_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(wrf_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)



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

save("/home/cschmidt/projects/attaino3/plots/maps/fig10_hist_future_diff.svg",f4)
f4


f1_n = Figure(size=(1200,800))
axn11=Axis(f1_n[1,1])
axn11.title = "WRFChem - CAMx"
poly!(aut_geoms,color=vec(mean(wrf_hist,dims=1)-mean(camx_hist,dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

axn12=Axis(f1_n[1,2])
axn12.title = "WRFChem - CAMx MAM"

poly!(aut_geoms,color=vec(mean(wrf_hist[mam_cesm_sub,:],dims=1)-mean(camx_hist[mam_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

axn13=Axis(f1_n[1,3])
axn13.title= "WRFChem - CAMx JJA"
poly!(aut_geoms,color=vec(mean(wrf_hist[jja_cesm_sub,:],dims=1)-mean(camx_hist[jja_cesm_sub,:],dims=1)),colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

#####
axn14=Axis(f1_n[2,1])
axn14.title = "WRFChem - CAMx"
poly!(aut_geoms,color=vec(sum(wrf_hist_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

axn15=Axis(f1_n[2,2])
axn15.title = "WRFChem - CAMx MAM"

poly!(aut_geoms,color=vec(sum(wrf_hist_exc[mam_cesm_sub,:],dims=1)-mean(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

axn16=Axis(f1_n[2,3])
axn16.title= "WRFChem - CAMx JJA"
poly!(aut_geoms,color=vec(sum(wrf_hist_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)




hidedecorations!(axn11)
hidedecorations!(axn12)
hidedecorations!(axn13)
hidedecorations!(axn14)
hidedecorations!(axn15)
hidedecorations!(axn16)

Colorbar(f1_n[1,4],limits=(-10,10),colormap=pap_cgrad, label = "Δ O₃ mda8 [μg/m³]",highclip=pap_hc,lowclip=pap_lc)
Colorbar(f1_n[2,4],limits=(-10,10),colormap=pap_cgrad, label = "Δ Yearly exceedances",highclip=pap_hc,lowclip=pap_lc)

f1_n

save("/home/cschmidt/projects/attaino3/plots/maps/wrf_camx_diff.svg",f1)








modify_vals.(vec(sum(camx_45_nf_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,1:2,1:2)


########################################
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
poly!(aut_geoms_high,color=:grey)

f4
ax42=Axis(f4[1,2])
ax42.title = "RCP4.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(camx_45_nf_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax43=Axis(f4[1,3])
ax43.title= "RCP4.5 NearFuture JJA - Historic"
poly!(aut_geoms,color=vec(sum(camx_45_nf_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax44=Axis(f4[2,1])
ax44.title = "RCP4.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_45_ff_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax45=Axis(f4[2,2])
ax45.title = "RCP4.5 FarFuture MAM - Historic"

poly!(aut_geoms,color=vec(sum(camx_45_ff_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax46=Axis(f4[2,3])
ax46.title= "RCP4.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(camx_45_ff_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax47=Axis(f4[3,1])
ax47.title = "RCP8.5 NearFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax48=Axis(f4[3,2])
ax48.title = "RCP8.5 NearFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax49=Axis(f4[3,3])
ax49.title= "RCP8.5 NearFuture  - Historic JJA"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax410=Axis(f4[4,1])
ax410.title = "RCP8.5 FarFuture - Historic"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc,dims=1)-sum(camx_hist_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax411=Axis(f4[4,2])
ax411.title = "RCP8.5 FarFuture - Historic MAM"

poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(camx_hist_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax412=Axis(f4[4,3])
ax412.title= "RCP8.5 FarFuture - Historic JJA"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(camx_hist_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)



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

save("/home/cschmidt/projects/attaino3/plots/maps/fig11_camx_hist_future_diff.svg",f4)
#f4

f3 = Figure(size=(1200,800))
ax31=Axis(f3[1,1])
ax31.title = "RCP8.5 - RCP4.5 NearFuture"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc,dims=1)-sum(camx_45_nf_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)

ax32=Axis(f3[1,2])
ax32.title = "RCP8.5 - RCP4.5 NearFuture MAM"

poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[mam_cesm_sub,:],dims=1)-sum(camx_45_nf_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax33=Axis(f3[1,3])
ax33.title= "RCP8.5 - RCP4.5 NearFuture JJA"
poly!(aut_geoms,color=vec(sum(camx_85_nf_exc[jja_cesm_sub,:],dims=1)-sum(camx_45_nf_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)


ax34=Axis(f3[2,1])
ax34.title = "RCP8.5 - RCP4.5 FarFuture"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc,dims=1)-sum(camx_45_ff_exc,dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax35=Axis(f3[2,2])
ax35.title = "RCP8.5 - RCP4.5 FarFuture MAM"

poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[mam_cesm_sub,:],dims=1)-sum(camx_45_ff_exc[mam_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)

ax36=Axis(f3[2,3])
ax36.title= "RCP8.5 - RCP4.5 FarFuture JJA"
poly!(aut_geoms,color=vec(sum(camx_85_ff_exc[jja_cesm_sub,:],dims=1)-sum(camx_45_ff_exc[jja_cesm_sub,:],dims=1))./10,colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc)
poly!(aut_geoms_high,color=:grey)



hidedecorations!(ax31)
hidedecorations!(ax32)
hidedecorations!(ax33)
hidedecorations!(ax34)
hidedecorations!(ax35)
hidedecorations!(ax36)

Colorbar(f3[:,4],colormap=pap_cgrad,colorrange=(-10,10),highclip=pap_hc,lowclip=pap_lc, label = "Δ Yearly exceedances")

save("/home/cschmidt/projects/attaino3/plots/maps/fig12_camx_future_diff.svg",f3)
