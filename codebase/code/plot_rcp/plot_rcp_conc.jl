using Plots,DelimitedFiles,StatsPlots,DataFrames,Colors,ColorSchemes,Measures

cd(@__DIR__)

linec1 = RGB(68/255,119/255,170/255)
linec2 = RGB(102/255,204/255,238/255)
linec3 = RGB(34/255,136/255,51/255)
linec4 = RGB(204/255,187/255,68/255)
linec5 = RGB(238/255,102/255,119/255)
linec6 = RGB(170/255,51/255,119/255)
linec7 = RGB(187/255,187/255,187/255)



datadir = "/home/cschmidt/data/rcp_concentrations"

input_files = readdir(datadir,join=true)
input_f = readdir(datadir)

input_files[4]


rcp45 = readdlm(input_files[4],skipstart=38)
rcp45_header = rcp45[1,:]
rcp45 = rcp45[2:end,:]


rcp85 = readdlm(input_files[7],skipstart=38)
rcp85_header = rcp85[1,:]
rcp85 = rcp85[2:end,:]

pl_cols =palette(:batlow,5)


rcp45[1,:]
findall(rcp45[:,1] .== 2000)


plot(rcp45[:,1],rcp45[:,5]/rcp45[236,5],label = "CH₄ RCP45",c=linec4,framestyle=:box,linewidth=2,rightmargin=:match,left_margin=3mm,legend=:bottomleft,legendfontsize=8,dpi=150)
plot!(rcp85[:,1],rcp85[:,5]/rcp85[236,5],label = "CH₄ RCP85",c=linec6,lw=2)
xlims!(2000,2062)
ylims!(0,2)
ylabel!("Relative change CH₄ concentrations")
vline!([2026,2035,2046,2055],color=:gray60,label=false)
annotate!(2030,1.8, "NF", :gray30)
annotate!(2050,1.8, "FF", :gray30)
annotate!(:topleft,"b)")
png("/home/cschmidt/projects/attaino3/plots/nox_voc_ch4_emissions_conc//methane_conc_rcp45_rcp85")

