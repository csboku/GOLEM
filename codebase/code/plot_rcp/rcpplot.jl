using CSV,DataFrames,Plots,Statistics

cd(@__DIR__)

linec1 = RGB(68/255,119/255,170/255)
linec2 = RGB(102/255,204/255,238/255)
linec3 = RGB(34/255,136/255,51/255)
linec4 = RGB(204/255,187/255,68/255)
linec5 = RGB(238/255,102/255,119/255)
linec6 = RGB(170/255,51/255,119/255)
linec7 = RGB(187/255,187/255,187/255)




datadir = "/home/cschmidt/data/rcp_regional/total"

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



rcp45[2,:]

rcp45[19,:]
rcp45[20,:]

rcp85[20,:]

rcp45[19,5:end] / rcp45

rcp45[19,5:end]

rcp45[19,5]

rcp45_mat = Matrix(rcp45)
rcp85_mat = Matrix(rcp85) 


plot(years,rcp45_mat[19,5:end]/rcp45_mat[19,5],label = "NOx rcp45",color=linec4, linewidth=1.5,framestyle=:box,legendfontsize=8,dpi=150,rightmargin=:match,left_margin=3mm)
plot!(years,Array(rcp85_mat[19,5:end]/rcp85_mat[19,5]), label = "NOx rcp85",color=linec6, linewidth=1.5)
vline!([2026,2035,2046,2055],color=:gray60,label=false)
plot!(years,rcp45_mat[20,5:end]/rcp45_mat[20,5],label = "VOC rcp45",color=linec4, linewidth=1.5,linestyle=:dash)
plot!(years,rcp85_mat[20,5:end]/rcp85_mat[20,5], label = "VOC rcp85",color=linec6, linewidth=1.5,linestyle=:dash)
annotate!(2030,0.9, "NF", :gray30)
annotate!(2050,0.9, "FF", :gray30)
ylabel!("Relative change emissions")
xlims!(2000,2062)
xlabel!("Year")
annotate!(:topleft,"a)")
png("/home/cschmidt/projects/attaino3/plots/nox_voc_ch4_emissions_conc/nox_voc_emissions.png")



png("emisions_nox_voc.png")