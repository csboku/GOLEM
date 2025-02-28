using CSV,CairoMakie,Statistics,Shapefile,Colors,ColorSchemes,DataFrames

cd(@__DIR__)


cspec = cgrad(:Spectral,10, rev = true,categorical=true)
cpuor = cgrad(:PuOr,10, rev = true,categorical=true)


att_wrf_hist_cesm = CSV.read("./input/HC2007t16-W-CESM-Cam-TNO3_O3_lonlat_bias_cor_countymapped_dmax.csv",DataFrame)

att_wrf_nf_rcp45 = CSV.read("./input/att_rcp45_2046t55_lonlat_bias_cor_countymapped_dmax.csv",DataFrame)



##### Fig 4 dmax diff for hist-rcp45




fig4 = Figure(resolution=(1200,800))
ax_fig4 = Axis(fig4[1,1])
oax = lines!(att_wrf_hist_cesm[:,3])
lines!(att_wrf_nf_rcp45[:,3])

ax_o3.ylabel = "lat"
ax_o3.xlabel = "lon"
ax_o3.title = "RCP8.5 - HIST  ALL Seasons"


###### Fig 5 exc diff for hist-rcp4 ff




