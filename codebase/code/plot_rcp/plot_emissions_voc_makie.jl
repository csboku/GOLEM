using CairoMakie,DelimitedFiles,DataFrames,Colors,ColorSchemes

cd(@__DIR__)


#### Read in CH4

datadir = "/sto2/data/lenian/data/rcp_concentrations"

input_files = readdir(datadir,join=true)
input_f = readdir(datadir)

input_files[4]


rcp45 = readdlm(input_files[4],skipstart=38)
rcp45_header = rcp45[1,:]
rcp45 = rcp45[2:end,:]


rcp85 = readdlm(input_files[7],skipstart=38)
rcp85_header = rcp85[1,:]
rcp85 = rcp85[2:end,:]

bcols = ["#0A7373", "#EDAA25", "#C43302"]



f1 = Figure(size=(1100,400))
ax1=Axis(f1[1,1],ylabel = "Relative change in concentration [%]")
lines!(rcp45[:,1],rcp45[:,5]/rcp45[236,5]*100,color=bcols[2],label = "CH₄ RCP4.5")
lines!(rcp85[:,1],rcp85[:,5]/rcp85[236,5]*100,color=bcols[3],label = "CH₄ RCP8.5")
xlims!(2000,2062)
ylims!(0,200)
axislegend(ax1,position=:lt)
vlines!([2026,2035,2046,2055],color=:gray60,label=false)
text!(ax1, 2030, 180, text = "NF", color = :gray30,label=false)
text!(ax1, 2050, 180, text = "FF", color = :gray30,label=false)
f1


datadir = "/sto2/data/lenian/data/rcp_regional/total"

data_files = readdir(datadir)
data_f = readdir(datadir, join=true)


rcp45 = CSV.read(data_f[1],DataFrame,decimal=',')

rcp85 = CSV.read(data_f[2],DataFrame,decimal=',')

rcp45[!,:Region] |> unique

rcp45[!,"Variable"] |> unique 

rcp45 = filter(:Region => ==("R5OECD"), rcp45)
rcp45 = filter(r -> any(occursin.(["Total"], r.Variable)), rcp45)

rcp85 = filter(:Region => ==("R5OECD"), rcp85)
rcp85 = filter(r -> any(occursin.(["Total"], r.Variable)), rcp85)

rcp45.Variable |> print

years = [2010:10:2100;]
years = vcat([2000,2005],years)


rcp45_mat = Matrix(rcp45)
rcp85_mat = Matrix(rcp85) 

ax2=Axis(f1[1,2],ylabel = "Relative change in emission [%]")

lines!(years,rcp45_mat[19,5:end]/rcp45_mat[19,5]*100,label = "NOₓ RCP4.5",color=bcols[2])
lines!(years,Array(rcp85_mat[19,5:end]/rcp85_mat[19,5])*100, label = "NOₓ RCP8.5",color=bcols[3])
lines!(years,rcp45_mat[20,5:end]/rcp45_mat[20,5]*100,label = "NMVOC RCP4.5",color=bcols[2], linewidth=1.5,linestyle=:dash)
lines!(years,rcp85_mat[20,5:end]/rcp85_mat[20,5]*100, label = "NMVOC RCP8.5",color=bcols[3], linewidth=1.5,linestyle=:dash)
axislegend(ax2,position=:lt)
xlims!(2000,2062)
ylims!(0,200)
vlines!([2026,2035,2046,2055],color=:gray60,label=false)
text!(ax2, 2030, 180, text = "NF", color = :gray30,label=false)
text!(ax2, 2050, 180, text = "FF", color = :gray30,label=false)
f1

save("fig2_emis_nocnmvoc_conc_ch4.png",f1)