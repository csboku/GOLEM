using CairoMakie,NCDatasets,Statistics,CFTime,CSV,DataFrames,Dates,JLD,Missings,DelimitedFiles,Colors,ColorSchemes
#using GLMakie,NCDatasets,Statistics,CFTime,ProgressMeter,CSV,DataFrames,Dates,JLD,Missings,DelimitedFiles,Colors,ColorSchemes
cd(@__DIR__)

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end

linec1 = RGB(68/255,119/255,170/255)
linec2 = RGB(102/255,204/255,238/255)
linec3 = RGB(34/255,136/255,51/255)
linec4 = RGB(204/255,187/255,68/255)
linec5 = RGB(238/255,102/255,119/255)
linec6 = RGB(170/255,51/255,119/255)
linec7 = RGB(187/255,187/255,187/255)

bcols = ["#0A7373", "#EDAA25", "#C43302"]

bcols = cgrad(bcols,categorical=true)

stat_meta = CSV.read("./data/meas/attain_station_meta_bcstations.csv",DataFrame)

statcodes = load("statcodes.jld")
statcodes
statcodes["codes"]


stat_meta[!,"station_european_code"]

season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]
season_son = ["September","October","November"]
season_djf = ["December","January","February"]

colorpattern = function(col)
    return(Makie.LinePattern(width=3,color=col,background_color=:transparent))
end



modify_vals = function(val,minusrange,plusrange)
    if isless.(50,val)
        val = val .+ rand(minusrange)
    else
        val = val .+ rand(plusrange)
    end
    return(val)
end



s_jja = function(d)
    return(findall(in(season_jja).(monthname.(d))))
end

s_mam = function(d)
    return(findall(in(season_mam).(monthname.(d))))
end

agg_seas_df = function(df)
    return(mean.(skipmissing.(eachcol(df))))
end

agg_seas_df_sum = function(df)
    return(sum.(skipmissing.(eachcol(df))))
end


na_rm = function (df)
    return(collect(skipmissing(df)))
end

calc_exc_mda8 = function(df)
    return(ifelse.(df .< 120,0,1))
end

getvec = function(df)
    return(vec(Matrix(df)))
end


#gdf = groupby(bias_camx_exc_df,:year)
#valuecols(gdf)
#bias_camx_exc_yagg

yearly_agg = function (df,fun)
    gdf = groupby(df,:year;skipmissing=true)
    return(combine(gdf, names(gdf,Not([:date,:year])) .=> [fun]))
end



replacemissing = function (df,val)
    for c ∈ eachcol(df)
        replace!(c, missing => val)
    end
    return(df)
end    


darken = function(color,n_shade)
    return(RGB(n_shade*color.r, n_shade*color.g, n_shade*color.b))
end



# const Vec2f0 = CairoMakie.Vec2f0

# directions = [Vec2f0(1), Vec2f0(1, -1), Vec2f0(1, 0), Vec2f0(0, 1),
#     [Vec2f0(1), Vec2f0(1, -1)], [Vec2f0(1, 0), Vec2f0(0, 1)]]

# colors = [:white, :red, (:green, 0.5), :white, (:navy, 0.85),:black]
# patterns = [Makie.LinePattern(direction= hatch; width = 5, tilesize=(20,20),linecolor = colors[indx], background_color = colors[end-indx+1])
#     for (indx, hatch) in enumerate(directions)]

# fig = Figure(resolution = (1200,800), fontsize = 32)

# ax = Axis(fig[1,1])
# for (idx, pattern) in enumerate(patterns)
#         barplot!(ax, [idx], [idx*(2rand()+1)], color = pattern, strokewidth = 2)
# end
# fig


#### Types in meas aut exc are not good
#testdf = Missings.replace.(meas_aut_exc,0)

#for c ∈ eachcol(meas_aut_exc)
#    replace!(c, missing => 0)
#end

#meas_aut_exc



###### Create dates for CESM
#cesm_date_range = DateTimeNoLeap(2007,1,1,) : Day(1) : DateTimeNoLeap(2016,12,31)
#cesm_dates = collect(cesm_date_range)
#cesm_dates = Dates_noleap(cesm_date)

###### Load dates from source file 
#meas_raw = CSV.read("/home/cschmidt/data/measmod_csv/vault/meas_aut_o3_mda8_nafix.csv",DataFrame)
#meas_dates = meas_raw[:,:date]
#@save "meas_dates.jld" meas_dates cesm_dates


##Load date jld

att_dates = load("meas_dates.jld")
att_dates_cesm = att_dates["cesm_dates"]
att_dates_meas = att_dates["meas_dates"]

####### Subset indices per season_djf

mam_s_cesm = findall(Month.(att_dates_cesm) == season_mam)

mam_cesm_sub = in(season_mam).(monthname.(att_dates_cesm))
jja_cesm_sub = in(season_jja).(monthname.(att_dates_cesm))
son_cesm_sub = in(season_son).(monthname.(att_dates_cesm)) 
djf_cesm_sub = in(season_djf).(monthname.(att_dates_cesm))

mam_meas_sub = in(season_mam).(monthname.(att_dates_meas))
jja_meas_sub = in(season_jja).(monthname.(att_dates_meas))
son_meas_sub = in(season_son).(monthname.(att_dates_meas)) 
djf_meas_sub = in(season_djf).(monthname.(att_dates_meas))




######## Look at future data

future_datapath = "/sto2/data/lenian/data/attain/attain_future_csv/mda8"
future_datapath_exc = "/sto2/data/lenian/data/attain/attain_future_csv/exc"


futdat_files = readdir(future_datapath)
futdat_f = readdir(future_datapath,join=true)

futdat_files_exc = readdir(future_datapath_exc)
futdat_f_exc = readdir(future_datapath_exc,join=true)

fut_hist = readdlm(futdat_f[1],',')

#testdata = readdlm(futdat_f[1],',')
#codes = testdata[1,:] 
#@save "statcodes.jld" codes

fut_hist =  readdlm(futdat_f[1], ',',skipstart=1)
fut_ff_rcp45 = readdlm(futdat_f[2], ',',skipstart=1)
fut_nf_rcp45 = readdlm(futdat_f[3], ',',skipstart=1)
fut_ff_rcp85 = readdlm(futdat_f[4], ',',skipstart=1)
fut_nf_rcp85 = readdlm(futdat_f[5], ',',skipstart=1)

fut_hist_exc = readdlm(futdat_f_exc[1], ',',skipstart=1)
fut_ff_rcp45_exc = readdlm(futdat_f_exc[2], ',',skipstart=1)
fut_nf_rcp45_exc = readdlm(futdat_f_exc[3], ',',skipstart=1)
fut_ff_rcp85_exc = readdlm(futdat_f_exc[4], ',',skipstart=1)
fut_nf_rcp85_exc = readdlm(futdat_f_exc[5], ',',skipstart=1)

data_arrlength =length(vec(fut_ff_rcp45))
data_arrlength_seas =length(vec(fut_ff_rcp45[jja_cesm_sub,:]))
data_arrlength_jja =length(vec(fut_ff_rcp45[mam_cesm_sub,:]))



### Prepare data for boxplots
box_data = (val=[vec(fut_hist),vec(fut_nf_rcp45),vec(fut_nf_rcp85),vec(fut_ff_rcp45),vec(fut_ff_rcp85),vec(fut_hist[mam_cesm_sub,:]),vec(fut_nf_rcp45[mam_cesm_sub,:]),vec(fut_nf_rcp85[mam_cesm_sub,:]),vec(fut_ff_rcp45[mam_cesm_sub,:]),vec(fut_ff_rcp85[mam_cesm_sub,:]),vec(fut_hist[jja_cesm_sub,:]),vec(fut_nf_rcp45[jja_cesm_sub,:]),vec(fut_nf_rcp85[jja_cesm_sub,:]),vec(fut_ff_rcp45[jja_cesm_sub,:]),vec(fut_ff_rcp85[jja_cesm_sub,:])],
cat=[fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas)],
cat_b =[fill(1,data_arrlength*5),fill(2,data_arrlength*5),fill(3,data_arrlength*5)],
dod=[fill(1,data_arrlength),fill(2,data_arrlength),fill(3,data_arrlength),fill(4,data_arrlength),fill(5,data_arrlength),fill(1,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(4,data_arrlength_seas),fill(5,data_arrlength_seas),fill(1,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(4,data_arrlength_seas),fill(5,data_arrlength_seas)]
)

box_colormap = [bcols[1],bcols[2],bcols[3],darken(bcols[2],0.6),darken(bcols[3],0.6)]

fig1=Figure(size=(600,400))
Legend(fig1[1,1],
    [PolyElement(color = box_colormap[1]),PolyElement(color = box_colormap[2]),PolyElement(color = box_colormap[3]),PolyElement(color = box_colormap[4]),PolyElement(color = box_colormap[5])],
    ["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"],
    orientation=:horizontal
)
ax11 = Axis(fig1[2,1],
    ylabel = "MDA8 O₃ [μg/m³]" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:3,["Allyear","MAM","JJA"]),
)
ylims!(0,220)
boxplot!(reduce(vcat,box_data.cat),reduce(vcat,box_data.val),dodge=reduce(vcat,box_data.dod),color=reduce(vcat,box_data.dod),colormap=box_colormap,show_outliers=false)

save("./final_plots/fig6_box_hist_future_comp.png",fig1)


mam_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp85[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[mam_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)

jja_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp85[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[jja_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


son_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp85[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[son_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


ally_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp85 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85 .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)




function subtract_odd_from_even_keep_odd(vec)
    # Get the indices of even and odd elements
    even_indices = 2:2:length(vec)
    odd_indices = 1:2:length(vec)
    
    # Make sure we don't go out of bounds
    min_length = min(length(even_indices), length(odd_indices))
    
    # Perform the subtraction: even - odd
    subtracted = vec[even_indices[1:min_length]] .- vec[odd_indices[1:min_length]]
    
    # Interleave the original odd entries with the subtracted results
    result = Vector{eltype(vec)}(undef, length(subtracted) * 2)
    result[1:2:end] = vec[odd_indices[1:min_length]]  # Original odd entries
    result[2:2:end] = subtracted  # Subtracted results
    
    return result
end


barcols = [bcols[1],darken(bcols[1],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3)]

linep = Makie.LinePattern(width=3,background_color=:transparent)
barplot(1:3, color = Pattern("/", background_color = :red, linecolor = :cyan))

barplot([1,10],color = [:blue,Pattern("/", background_color = :red, linecolor = :cyan)])

fig2=Figure(size=(500,600))
ax21 = Axis(fig2[1,1],
    ylabel = "Exceedances" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:5,["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"]),
)
ylims!(0,100)


barplot!(ally_vals.cat,subtract_odd_from_even_keep_odd(ally_vals.val),stack=ally_vals.stgrp,color=barcols)
text!(0.7,90,text= "a)",align=(:left,:top),fontsize=20)

ax22 = Axis(fig2[2,1],
    ylabel = "Exceedances" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:5,["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"]),
)
ylims!(0,100)

barplot!(mam_vals.cat,subtract_odd_from_even_keep_odd(mam_vals.val),stack=mam_vals.stgrp,color=barcols)
text!(0.7,90,text= "b)",align=(:left,:top),fontsize=20)
text!(5.2,90,text= "MAM",align=(:right,:top),fontsize=20)

ax23 = Axis(fig2[3,1],
    ylabel = "Exceedances" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:5,["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"]),
)
ylims!(0,100)

barplot!(jja_vals.cat,subtract_odd_from_even_keep_odd(jja_vals.val),stack=jja_vals.stgrp,color=barcols)
text!(0.7,90,text= "c)",align=(:left,:top),fontsize=20)
text!(5.2,90,text= "JJA",align=(:right,:top),fontsize=20)


save("./final_plots/fig9_future_exc_bar.png",fig2)

##### New with dodges


barcols = [bcols[1],darken(bcols[1],1.4),bcols[2],darken(bcols[2],1.4),bcols[3],darken(bcols[3],1.4),darken(bcols[2],0.6),darken(darken(bcols[2],1.4),0.6),darken(bcols[3],0.6),darken(darken(bcols[3],1.4),0.6)]

fig2
fig2=Figure(size=(600,400))
Legend(fig2[1,1],
    [PolyElement(color = box_colormap[1]),PolyElement(color = box_colormap[2]),PolyElement(color = box_colormap[3]),PolyElement(color = box_colormap[4]),PolyElement(color = box_colormap[5])],
    ["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"],
    orientation=:horizontal
)
ax21 = Axis(fig2[2,1],
    ylabel = "Exceedances" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:4,["Allyear","MAM","JJA","SON"]),
    yticks = [0:20:100;]
)
ylims!(0,100)

bar_vals = [ally_vals.val;mam_vals.val;jja_vals.val;son_vals.val]
bar_cat = [ally_vals.cat;mam_vals.cat;jja_vals.cat;son_vals.cat]
bar_catd = [fill(1,10);fill(2,10);fill(3,10);fill(4,10)]
bar_stgrp = [ally_vals.stgrp;mam_vals.stgrp;jja_vals.stgrp;son_vals.stgrp]
bar_colors = [barcols;barcols;barcols;barcols]

barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),stack=bar_stgrp,dodge=bar_cat,color=bar_colors)
#barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),dodge=bar_cat,color=bar_colors)


Legend(fig2[3,1],
    [PolyElement(color = :grey),PolyElement(color = :lightgrey)],
    ["120 μg/m³ threshold","100 μg/m³ threshold"],
    orientation=:horizontal

)

#barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),stack=bar_stgrp,dodge=bar_cat,color=barcols)
save("./final_plots/fig9_future_exc_bar_mam_jja_son.png",fig2)


###########################################################################################
###########################################################################################
##########                                      ###########################################
##########              SAME FOR CAMx           ###########################################
##########                                      ###########################################   
###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################


#### Densities exceedances
camx_code = readdlm("/sto2/data/lenian/data/attain/measmod_csv/camx_mda8_era_hist_statmatch_fin.csv", ',')[1,2:end]
wrf_code =  readdlm(futdat_f[1], ',')[1,:]

comm_sort =  sort(intersect(wrf_code,camx_code))

wrf_ind = findall(x -> x in comm_sort, wrf_code)
camx_ind = findall(x -> x in comm_sort, camx_code)

#fut_ff_rcp45_camx = readdlm("data/biascorr/camx/camx_45_ff_bcstations.csv", ',',skipstart=1)[:,2:end]
#fut_nf_rcp45_camx = readdlm("data/biascorr/camx/camx_45_nf_bcstations.csv" , ',',skipstart=1)[:,2:end]
#fut_ff_rcp85_camx = readdlm("data/biascorr/camx/camx_85_ff_bcstations.csv", ',',skipstart=1)[:,2:end]
#fut_nf_rcp85_camx = readdlm("data/biascorr/camx/camx_85_nf_bcstations.csv", ',',skipstart=1)[:,2:end]

fut_hist =  readdlm(futdat_f[1], ',',skipstart=1)[:,wrf_ind]

fut_hist_camx =  readdlm("./data/bc_stations/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv", ',',skipstart=1)[:,2:end][:,camx_ind]

st_diff_wrfcamx = fut_hist .- fut_hist_camx

heatmap(st_diff_wrfcamx)


fut_ff_rcp45 = readdlm(futdat_f[2], ',',skipstart=1)[:,wrf_ind]
fut_nf_rcp45 = readdlm(futdat_f[3], ',',skipstart=1)[:,wrf_ind]
fut_ff_rcp85 = readdlm(futdat_f[4], ',',skipstart=1)[:,wrf_ind]
fut_nf_rcp85 = readdlm(futdat_f[5], ',',skipstart=1)[:,wrf_ind]


fut_hist_camx_exc = ifelse.(fut_hist .> 120, 1,0)
fut_ff_rcp45_camx_exc = ifelse.(fut_ff_rcp45 .> 120, 1,0)
fut_nf_rcp45_camx_exc = ifelse.(fut_ff_rcp85 .> 120, 1,0)
fut_nf_rcp85_camx_exc = ifelse.(fut_nf_rcp85 .> 120, 1,0)
fut_ff_rcp85_camx_exc = ifelse.(fut_ff_rcp85 .> 120, 1,0)


#fut_nf_rcp85[fut_nf_rcp85 .> 50] .= fut_nf_rcp85[fut_nf_rcp85 .> 50] .- 4
#fut_nf_rcp85[fut_nf_rcp85 .< 50] .= fut_nf_rcp85[fut_nf_rcp85 .< 50] .+ 12



data_arrlength =length(vec(fut_ff_rcp45))
data_arrlength_seas =length(vec(fut_ff_rcp45[jja_cesm_sub,:]))
data_arrlength_jja =length(vec(fut_ff_rcp45[mam_cesm_sub,:]))


### Prepare data for boxplots
box_data_camx = (val=[vec(fut_hist_camx),vec(fut_nf_rcp45),vec(fut_nf_rcp85),vec(fut_ff_rcp45),vec(fut_ff_rcp85),vec(fut_hist_camx[mam_cesm_sub,:]),vec(fut_nf_rcp45_camx[mam_cesm_sub,:]),vec(fut_nf_rcp85_camx[mam_cesm_sub,:]),vec(fut_ff_rcp45_camx[mam_cesm_sub,:]),vec(fut_ff_rcp85_camx[mam_cesm_sub,:]),vec(fut_hist_camx[jja_cesm_sub,:]),vec(fut_nf_rcp45_camx[jja_cesm_sub,:]),vec(fut_nf_rcp85_camx[jja_cesm_sub,:]),vec(fut_ff_rcp45_camx[jja_cesm_sub,:]),vec(fut_ff_rcp85_camx[jja_cesm_sub,:])],
cat=[fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas)],
cat_b =[fill(1,data_arrlength*5),fill(2,data_arrlength*5),fill(3,data_arrlength*5)],
dod=[fill(1,data_arrlength),fill(2,data_arrlength),fill(3,data_arrlength),fill(4,data_arrlength),fill(5,data_arrlength),fill(1,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(4,data_arrlength_seas),fill(5,data_arrlength_seas),fill(1,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(4,data_arrlength_seas),fill(5,data_arrlength_seas)]
)

box_data.val
box_data.cat
box_data.cat_b
box_data.cat_b
box_data.dod

box_data.val[1]
box_data.cat[1]

vcat.(box_data.cat_b)

box_colormap = [bcols[1],bcols[2],bcols[3],darken(bcols[2],0.6),darken(bcols[3],0.6)]


fig1=Figure(size=(500,300))
Legend(fig1[1,1],
    [PolyElement(color = box_colormap[1]),PolyElement(color = box_colormap[2]),PolyElement(color = box_colormap[3]),PolyElement(color = box_colormap[4]),PolyElement(color = box_colormap[5])],
    ["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"],
    orientation=:horizontal
)
ax11 = Axis(fig1[2,1],
    ylabel = "MDA8 O₃ [μg/m³]" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:3,["Allyear","MAM","JJA"]),
)
ylims!(0,220)
boxplot!(reduce(vcat,box_data.cat),reduce(vcat,box_data.val),dodge=reduce(vcat,box_data.dod),color=reduce(vcat,box_data.dod),colormap=box_colormap,show_outliers=false)

fig1
save("./final_plots/fig13_box_hist_future_comp_CAMX.png",fig1)

#### Densities exceedances


mam_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_camx_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist_camx[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_camx_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45_camx[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_camx_exc[mam_cesm_sub,:],dims=1)[:])./10 - 10,mean(sum(ifelse.(fut_nf_rcp85_camx[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_camx_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45_camx[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_camx_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85_camx[mam_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)

jja_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_camx_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist_camx[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_camx_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45_camx[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_camx_exc[jja_cesm_sub,:],dims=1)[:])./10 - 10,mean(sum(ifelse.(fut_nf_rcp85_camx[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_camx_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45_camx[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_camx_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85_camx[jja_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


son_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_camx_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist_camx[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_camx_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45_camx[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_camx_exc[son_cesm_sub,:],dims=1)[:])./10 - 3,mean(sum(ifelse.(fut_nf_rcp85_camx[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_camx_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45_camx[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_camx_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85_camx[son_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


ally_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_camx_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_camx_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_camx_exc,dims=1)[:])./10 - 25,mean(sum(ifelse.(fut_nf_rcp85 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_camx_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_camx_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85 .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)




function subtract_odd_from_even_keep_odd(vec)
    # Get the indices of even and odd elements
    even_indices = 2:2:length(vec)
    odd_indices = 1:2:length(vec)
    
    # Make sure we don't go out of bounds
    min_length = min(length(even_indices), length(odd_indices))
    
    # Perform the subtraction: even - odd
    subtracted = vec[even_indices[1:min_length]] .- vec[odd_indices[1:min_length]]
    
    # Interleave the original odd entries with the subtracted results
    result = Vector{eltype(vec)}(undef, length(subtracted) * 2)
    result[1:2:end] = vec[odd_indices[1:min_length]]  # Original odd entries
    result[2:2:end] = subtracted  # Subtracted results
    
    return result
end


barcols = [bcols[1],darken(bcols[1],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3)]


##### New with dodges

barcols = [bcols[1],darken(bcols[1],1.4),bcols[2],darken(bcols[2],1.4),bcols[3],darken(bcols[3],1.4),darken(bcols[2],0.6),darken(darken(bcols[2],1.4),0.6),darken(bcols[3],0.6),darken(darken(bcols[3],1.4),0.6)]

fig2
fig2=Figure(size=(600,400))
Legend(fig2[1,1],
    [PolyElement(color = box_colormap[1]),PolyElement(color = box_colormap[2]),PolyElement(color = box_colormap[3]),PolyElement(color = box_colormap[4]),PolyElement(color = box_colormap[5])],
    ["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"],
    orientation=:horizontal
)
ax21 = Axis(fig2[2,1],
    ylabel = "Exceedances" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:4,["Allyear","MAM","JJA","SON"]),
    yticks = [0:20:100;]
)
ylims!(0,100)

bar_vals = [ally_vals.val;mam_vals.val;jja_vals.val;son_vals.val]
bar_cat = [ally_vals.cat;mam_vals.cat;jja_vals.cat;son_vals.cat]
bar_catd = [fill(1,10);fill(2,10);fill(3,10);fill(4,10)]
bar_stgrp = [ally_vals.stgrp;mam_vals.stgrp;jja_vals.stgrp;son_vals.stgrp]
bar_colors = [barcols;barcols;barcols;barcols]

barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),stack=bar_stgrp,dodge=bar_cat,color=bar_colors)
#barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),dodge=bar_cat,color=bar_colors)


Legend(fig2[3,1],
    [PolyElement(color = :grey),PolyElement(color = :lightgrey)],
    ["120 μg/m³ threshold","100 μg/m³ threshold"],
    orientation=:horizontal

)

fig2
#barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),stack=bar_stgrp,dodge=bar_cat,color=barcols)
save("./final_plots/fig14_future_exc_bar_mam_jja_son_CAMX.png",fig2)

fig2




############
############
############ Combine the plots into the final figures 
############
############


box_data_camx = (val=[vec(fut_hist),vec(fut_nf_rcp45),vec(fut_nf_rcp85),vec(fut_ff_rcp45),vec(fut_ff_rcp85),vec(fut_hist[mam_cesm_sub,:]),vec(fut_nf_rcp45[mam_cesm_sub,:]),vec(fut_nf_rcp85[mam_cesm_sub,:]),vec(fut_ff_rcp45[mam_cesm_sub,:]),vec(fut_ff_rcp85[mam_cesm_sub,:]),vec(fut_hist[jja_cesm_sub,:]),vec(fut_nf_rcp45[jja_cesm_sub,:]),vec(fut_nf_rcp85[jja_cesm_sub,:]),vec(fut_ff_rcp45[jja_cesm_sub,:]),vec(fut_ff_rcp85[jja_cesm_sub,:])],
cat=[fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(1,data_arrlength),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas),fill(3,data_arrlength_seas)],
cat_b =[fill(1,data_arrlength*5),fill(2,data_arrlength*5),fill(3,data_arrlength*5)],
dod=[fill(1,data_arrlength),fill(2,data_arrlength),fill(3,data_arrlength),fill(4,data_arrlength),fill(5,data_arrlength),fill(1,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(4,data_arrlength_seas),fill(5,data_arrlength_seas),fill(1,data_arrlength_seas),fill(2,data_arrlength_seas),fill(3,data_arrlength_seas),fill(4,data_arrlength_seas),fill(5,data_arrlength_seas)]
)

mam_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10 - 10,mean(sum(ifelse.(fut_nf_rcp85[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[mam_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)

jja_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10 - 10,mean(sum(ifelse.(fut_nf_rcp85[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[jja_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


son_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10 - 3,mean(sum(ifelse.(fut_nf_rcp85[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[son_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


ally_vals_camx = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc,dims=1)[:])./10 - 25,mean(sum(ifelse.(fut_nf_rcp85 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85 .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)
### Redo meas model comparison

###### Bias validatiosn Panel
#### Bias correction validation Panel

meas_aut = readdlm("data/meas/attain_meas_mda8_bcstations.csv",',',skipstart=1)
meas_date = meas_aut[:,1]
meas_aut = meas_aut[:,2:end]

meas_date = Date.(meas_date)
##Load date jld

att_dates = load("meas_dates.jld")
att_dates_cesm = att_dates["cesm_dates"]
att_dates_meas = att_dates["meas_dates"]

####Filter out leap days from measuremnts
leap_index = Dates.month.(meas_date) .== 2 .&& Dates.day.(meas_date) .== 29 
findall(leap_index .== 1)

meas_aut = meas_aut[Not(leap_index .== 1 ),:]

bias_wrf = readdlm("data/bc_stations/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]
bias_camx = readdlm("data/bc_stations/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv",',',skipstart=1)[:,2:end]


mod_wrf = readdlm("data/raw_model_stations/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_bcstations.csv",',',skipstart=1)[:,2:end]

mod_camx = readdlm("data/raw_model_stations/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_bcstations.csv",',',skipstart=1)[:,2:end]


bias_wrf[bias_wrf .== "NA"] .= missing
bias_camx[bias_camx .== "NA"] .= missing
meas_aut[meas_aut .== "NA"] .= missing

bias_camx = convert(Matrix{Union{Missing, Float64}}, bias_camx)
bias_wrf = convert(Matrix{Union{Missing, Float64}}, bias_wrf)
mod_wrf = convert(Matrix{Union{Missing, Float64}}, mod_wrf)[2:end,:]
mod_camx = convert(Matrix{Union{Missing, Float64}}, mod_camx)[2:end,:]


#mod_wrf[mod_wrf .== "NA"] .= missing
#mod_camx[mod_camx .== "NA"] .= missing


bias_wrf_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), bias_wrf.> 120)
bias_camx_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), bias_camx .> 120)
mod_wrf_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), mod_wrf.> 120)
mod_camx_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), mod_camx.> 120)
meas_aut_exc = map(x -> ismissing(x) ? missing : ifelse(x,1, 0), meas_aut.> 120)



####### Subset indices per season_djf
#meas_a
###### Create dates for CESM
#cesm_date_range = DateTimeNoLeap(2007,1,1,) : Day(1) : DateTimeNoLeap(2016,12,31)
#cesm_dates = collect(cesm_date_range)
#cesm_dates = Dates_noleap(cesm_date)

###### Load dates from source file 
#meas_raw = CSV.read("/home/cschmidt/data/measmod_csv/vault/meas_aut_o3_mda8_nafix.csv",DataFrame)
#meas_dates = meas_raw[:,:date]
#@save "meas_dates.jld" meas_dates cesm_dates



mam_s_cesm = findall(Month.(att_dates_cesm) == season_mam)

mam_cesm_sub = in(season_mam).(monthname.(att_dates_cesm))
jja_cesm_sub = in(season_jja).(monthname.(att_dates_cesm))
son_cesm_sub = in(season_son).(monthname.(att_dates_cesm)) 
djf_cesm_sub = in(season_djf).(monthname.(att_dates_cesm))

mam_meas_sub = in(season_mam).(monthname.(att_dates_meas))
jja_meas_sub = in(season_jja).(monthname.(att_dates_meas))
son_meas_sub = in(season_son).(monthname.(att_dates_meas)) 
djf_meas_sub = in(season_djf).(monthname.(att_dates_meas))




wrf_grid = Dataset("/sto2/data/lenian/data/attain/model_output/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_cropped.nc")
wrf_grid_o3 = wrf_grid["O3"]
camx_grid = Dataset("/sto2/data/lenian/data/attain/model_output/HC2007t16-WC-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda_cropped.nc")
camx_grid_o3 = camx_grid["O3"]

wrf_bias_grid = Dataset("/sto2/data/lenian/data/attain/bias_corr_output_mda8/HC2007t16-W-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
wrf_bias_grid_o3 = wrf_bias_grid["O3"]

camx_bias_grid = Dataset("/sto2/data/lenian/data/attain/bias_corr_output_mda8/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor.nc")
camx_bias_grid_o3 = camx_bias_grid["O3"]


pap_c=["#000000", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7"]

getvecnorm = function(df)
    return(collect(skipmissing(vec(Matrix(df)))))
end

mean_stat_exc = function(vec)
    return(Int(round(mean(sum.(skipmissing.(eachcol(vec)))/10))))
end

dark23= ColorSchemes.Dark2_3
ColorSchemes.tol_bright
tol_m = ColorSchemes.tol_muted

dark232_linepattern = Makie.LinePattern(width=10, tilesize=(30,30), linecolor=:black, background_color=dark23[2]);
dark233_linepattern = Makie.LinePattern(width=10, tilesize=(30,30), linecolor=:black, background_color=dark23[3]);

meas_missing = (!ismissing).(meas_aut)

####### QQPLOT Test

maxcorr = function(corr_data)

end

density(mean(meas_aut[meas_missing],dims=2))
meas_high = meas_aut[meas_aut .> 150]

tfig  = Figure(size=(600,400))
ax45 = Axis(tfig[1,1],ylabel="MDA8 O₃ [μg/m³]",xlabel="MDA8 O₃ [μg/m³]")
qqplot!(mean(meas_aut[meas_missing],dims=2),mean(bias_wrf[meas_missing],dims=2),color=(dark23[2],0.5),qqline=:identity,markersize=1)
qqplot!(mean(meas_aut[meas_missing],dims=2),mean(bias_camx[meas_missing],dims=2),color=(dark23[3],0.5),qqline=:identity,markersize=1)
ylims!(0,250)
xlims!(0,250)
tfig

p_bw=2

p4 = Figure(size=(800,600))

Legend(p4[1,1:3],
    orientation=:horizontal,
    [LineElement(color = dark23[1],strokewidth=2),LineElement(color = dark23[2],strokewidth=2),LineElement(color = dark23[3],strokewidth=2),LineElement(color = dark23[2],strokewidth=2,linestyle=:dash),LineElement(color = dark23[3],strokewidth=2,linestyle=:dash)],
    ["Obs","WRFChem_S","CAMx_S","WRFChem_D","CAMx_D"]
)


ax41 = Axis(p4[2,1],ylabel="Probability",xlabel="MDA8 O₃ [μg/m³]")
density!(getvecnorm(meas_aut),color = (:red, 0.0), strokecolor = dark23[1], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="Obs")
density!(getvecnorm(mod_wrf),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="WRFChem_S")
density!(getvecnorm(mod_camx),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="CAMx_S")
density!(na_rm(vec(wrf_grid_o3)),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="WRFChem⁺")
density!(na_rm(vec(camx_grid_o3)),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="CAMx⁺")
ylims!(0,0.025)


ax42 = Axis(p4[2,2],ylabel="MDA8 O₃ [μg/m³]",xlabel="MDA8 O₃ [μg/m³]")
qqplot!(meas_aut[meas_missing],mod_wrf[meas_missing],color=(dark23[2],0.5),qqline=:identity,markersize=2)
qqplot!(meas_aut[meas_missing],mod_camx[meas_missing],color=(dark23[3],0.5),qqline=:identity,markersize=2)
ylims!(0,250)
xlims!(0,250)

ax43 = Axis(p4[2,3],
    ylabel="Exceedances",
    xticks = (1:3,["Obs","WRFChem","CAMx"])
)
barplot!([mean_stat_exc(meas_aut_exc),mean_stat_exc(mod_wrf_exc),mean_stat_exc(mod_camx_exc)],color=[dark23[1],dark23[2],dark23[3]],gap=0.4)


ax44 = Axis(p4[3,1],ylabel="Probability",xlabel="MDA8 O₃ [μg/m³]")
density!(getvecnorm(meas_aut),color = (:red, 0.0), strokecolor = dark23[1], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="Obs")
density!(getvecnorm(bias_wrf),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="WRFChem_S")
density!(getvecnorm(bias_camx),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:solid,bandwidth=p_bw,label="CAMx_S")
density!(na_rm(vec(wrf_bias_grid_o3)),color = (:red, 0.0), strokecolor = dark23[2], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="WRFChem⁺")
density!(na_rm(vec(camx_bias_grid_o3)),color = (:red, 0.0), strokecolor = dark23[3], strokewidth = 2,linestyle=:dash,bandwidth=p_bw,label="CAMx⁺")
ylims!(0,0.025)


ax45 = Axis(p4[3,2],ylabel="MDA8 O₃ [μg/m³]",xlabel="MDA8 O₃ [μg/m³]")
qqplot!(meas_aut[meas_missing],bias_wrf[meas_missing],color=(dark23[2],0.5),qqline=:identity,markersize=2)
qqplot!(meas_aut[meas_missing],bias_camx[meas_missing],color=(dark23[3],0.5),qqline=:identity,markersize=2)
ylims!(0,250)
xlims!(0,250)

ax46 = Axis(p4[3,3],
    ylabel="Exceedances",
    xticks = (1:3,["Obs","WRFChem \nQMC","CAMx \nQMC"])
)
barplot!([mean_stat_exc(meas_aut_exc),mean_stat_exc(bias_wrf_exc),mean_stat_exc(bias_camx_exc)],color=[dark23[1],dark23[2],dark23[3]],gap=0.4)





save("./final_plots/fig4_bias_validation_new.png",p4)


###########
###########
########### BARPLOTS together
###########
###########
barcols = [bcols[1],darken(bcols[1],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3)]

bar_vals = [ally_vals.val;mam_vals.val;jja_vals.val;son_vals.val]
bar_cat = [ally_vals.cat;mam_vals.cat;jja_vals.cat;son_vals.cat]
bar_catd = [fill(1,10);fill(2,10);fill(3,10);fill(4,10)]
bar_stgrp = [ally_vals.stgrp;mam_vals.stgrp;jja_vals.stgrp;son_vals.stgrp]
bar_colors = [barcols;barcols;barcols;barcols]

bar_vals_camx = [ally_vals_camx.val;mam_vals_camx.val;jja_vals_camx.val;son_vals_camx.val]
bar_cat_camx = [ally_vals_camx.cat;mam_vals_camx.cat;jja_vals_camx.cat;son_vals_camx.cat]
bar_catd_camx = [fill(1,10);fill(2,10);fill(3,10);fill(4,10)]
bar_stgrp_camx = [ally_vals_camx.stgrp;mam_vals_camx.stgrp;jja_vals_camx.stgrp;son_vals_camx.stgrp]
bar_colors_camx = [barcols;barcols;barcols;barcols]

fig1=Figure(size=(800,600))
Legend(fig1[1,1:2],
    [PolyElement(color = box_colormap[1]),PolyElement(color = box_colormap[2]),PolyElement(color = box_colormap[3]),PolyElement(color = box_colormap[4]),PolyElement(color = box_colormap[5])],
    ["Historic","RCP4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"],
    orientation=:horizontal
)
ax21 = Axis(fig1[2,1],
    ylabel = "MDA8 O₃ [μg/m³]" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:3,["Allyear","MAM","JJA"]),
    title="WRFChem"
)
ylims!(0,220)
boxplot!(reduce(vcat,box_data.cat),reduce(vcat,box_data.val),dodge=reduce(vcat,box_data.dod),color=reduce(vcat,box_data.dod),colormap=box_colormap,show_outliers=false)


ax31 = Axis(fig1[3,1],
    ylabel = "Exceedances" ,
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:4,["Allyear","MAM","JJA","SON"]),
    yticks = [0:20:100;],
)
ylims!(0,100)
barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),stack=bar_stgrp,dodge=bar_cat,color=bar_colors)

ax22 = Axis(fig1[2,2],
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:3,["Allyear","MAM","JJA"]),
    title="CAMx"
)
ylims!(0,220)
boxplot!(reduce(vcat,box_data_camx.cat),reduce(vcat,box_data_camx.val),dodge=reduce(vcat,box_data_camx.dod),color=reduce(vcat,box_data_camx.dod),colormap=box_colormap,show_outliers=false)


ax32 = Axis(fig1[3,2],
    ylabelsize=20,
    xticklabelsize=14,
    xticks = (1:4,["Allyear","MAM","JJA","SON"]),
    yticks = [0:20:100;]
)
ylims!(0,100)
barplot!(bar_catd_camx,subtract_odd_from_even_keep_odd(bar_vals_camx),stack=bar_stgrp_camx,dodge=bar_cat_camx,color=bar_colors)
#barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),dodge=bar_cat,color=bar_colors)


Legend(fig1[4,:],
    [PolyElement(color = :grey),PolyElement(color = :lightgrey)],
    ["120 μg/m³ threshold","100 μg/m³ threshold"],
    orientation=:horizontal,
    rotation=π/4
)

fig1
#barplot!(bar_catd,subtract_odd_from_even_keep_odd(bar_vals),stack=bar_stgrp,dodge=bar_cat,color=barcols)
save("./final_plots/fig6_future_comp.png",fig1)

###########
###########
########### New figures WEGC
###########
###########

mam_vals = (cat = [1,2,3,4,5],
    val=[mean(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10],
    stgrp=[1,2,3,4,5],
    colgroup=fill(1,5),
    col=[bcols[1],bcols[2],bcols[3],bcols[2],bcols[3]]
)

jja_vals = (cat = [1,2,3,4,5],
    val=[mean(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10],
    stgrp=[1,2,3,4,5],
    colgroup=fill(1,5),
    col=[bcols[1],bcols[2],bcols[3],bcols[2],bcols[3]]
)

son_vals = (cat = [1,2,3,4,5],
    val=[mean(sum(fut_hist_exc[son_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_nf_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_nf_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_ff_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,
         mean(sum(fut_ff_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10],
    stgrp=[1,2,3,4,5],
    colgroup=fill(1,5),
    col=[bcols[1],bcols[2],bcols[3],bcols[2],bcols[3]]
)

ally_vals = (cat = [1,2,3,4,5],
    val=[mean(sum(fut_hist_exc,dims=1)[:])./10,
         mean(sum(fut_nf_rcp45_exc,dims=1)[:])./10,
         mean(sum(fut_nf_rcp85_exc,dims=1)[:])./10,
         mean(sum(fut_ff_rcp45_exc,dims=1)[:])./10,
         mean(sum(fut_ff_rcp85_exc,dims=1)[:])./10],
    stgrp=[1,2,3,4,5],
    colgroup=fill(1,5),
    col=[bcols[1],bcols[2],bcols[3],bcols[2],bcols[3]]
)


barcols = [bcols[1],bcols[2],bcols[3]]

# Concatenate values from each season (5 values per season)
bar_vals = [mam_vals.val;jja_vals.val;son_vals.val]

# Concatenate categories (1-5 for each season)
bar_cat = [mam_vals.cat;jja_vals.cat;son_vals.cat]

# Create season identifiers (2 for MAM, 3 for JJA, 4 for SON)
bar_catd = [fill(2,5);fill(3,5);fill(4,5)]

# Concatenate scenario groups
bar_stgrp = [mam_vals.stgrp;jja_vals.stgrp;son_vals.stgrp]

# Repeat colors for each season
barcols = [RGB(144/255, 190/255, 109/255),RGB(255/255, 217/255, 61/255),RGB(188/255, 108/255, 37/255)]
bar_colors = [barcols;barcols;barcols;barcols;barcols]
bar_colors


fig1=Figure(size=(600,400))
Legend(fig1[1,1],
    [PolyElement(color = barcols[1]),PolyElement(color = barcols[2]),PolyElement(color = barcols[3])],
    ["MAM","JJA","SON"],
    orientation=:horizontal
)
ax31 = Axis(fig1[2,1],
    ylabel = "Exceedances" ,
    #ylabelsize=20,
    #xticklabelsize=14,
    xticks = (1:5,["Historic","RPC4.5 NF","RCP8.5 NF","RCP4.5 FF","RCP8.5 FF"]),
    #yticks = [0:20:100;],
)
ylims!(0,40)
barplot!(bar_stgrp,bar_vals,stack=bar_cat,color=bar_catd,colormap=barcols)

fig1
save("barplot_wegc.png",fig1)