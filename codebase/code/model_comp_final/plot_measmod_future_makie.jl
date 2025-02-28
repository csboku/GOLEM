using CairoMakie,NCDatasets,Statistics,CFTime,ProgressMeter,CSV,DataFrames,Dates,JLD,Missings,DelimitedFiles,Colors

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

future_datapath = "/home/cschmidt/data/attain/attain_future_csv/mda8"
future_datapath_exc = "/home/cschmidt/data/attain/attain_future_csv/exc"


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

box_data.val
box_data.cat
box_data.cat_b
box_data.cat_b
box_data.dod
box_data.val[1]
box_data.cat[1]


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

save("/home/cschmidt/projects/attaino3/plots/PUB/fig6_box_hist_future_comp.svg",fig1)


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


darken(bcols[1],1.1)

ally_vals.val


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

subtract_odd_from_even_keep_odd(ally_vals.val)

barcols = [bcols[1],darken(bcols[1],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3),bcols[2],darken(bcols[2],1.3),bcols[3],darken(bcols[3],1.3)]

fig2
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


save("/home/cschmidt/projects/attaino3/plots/future_bar/fig9_future_exc_bar.svg",fig2)

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
save("/home/cschmidt/projects/attaino3/plots/PUB/fig9_future_exc_bar_mam_jja_son.svg",fig2)


###########################################################################################
###########################################################################################
##########                                      ###########################################
##########              SAME FOR CAMx           ###########################################
##########                                      ###########################################   
###########################################################################################
###########################################################################################
###########################################################################################
###########################################################################################




fut_hist =  readdlm("data/biascorr/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv", ',',skipstart=1)[:,2:end]
fut_ff_rcp45 = readdlm("data/biascorr/camx/camx_45_ff_bcstations.csv", ',',skipstart=1)[:,2:end]
fut_nf_rcp45 = readdlm("data/biascorr/camx/camx_45_nf_bcstations.csv" , ',',skipstart=1)[:,2:end]
fut_ff_rcp85 = readdlm("data/biascorr/camx/camx_85_ff_bcstations.csv", ',',skipstart=1)[:,2:end]
fut_nf_rcp85 = readdlm("data/biascorr/camx/camx_85_nf_bcstations.csv", ',',skipstart=1)[:,2:end]

fut_hist_exc = ifelse.(fut_hist .> 120, 1,0)
fut_ff_rcp45_exc = ifelse.(fut_ff_rcp45 .> 120, 1,0)
fut_nf_rcp45_exc = ifelse.(fut_ff_rcp85 .> 120, 1,0)
fut_nf_rcp85_exc = ifelse.(fut_nf_rcp85 .> 120, 1,0)
fut_ff_rcp85_exc = ifelse.(fut_ff_rcp85 .> 120, 1,0)


fut_nf_rcp85[fut_nf_rcp85 .> 50] .= fut_nf_rcp85[fut_nf_rcp85 .> 50] .- 4
fut_nf_rcp85[fut_nf_rcp85 .< 50] .= fut_nf_rcp85[fut_nf_rcp85 .< 50] .+ 12



data_arrlength =length(vec(fut_ff_rcp45))
data_arrlength_seas =length(vec(fut_ff_rcp45[jja_cesm_sub,:]))
data_arrlength_jja =length(vec(fut_ff_rcp45[mam_cesm_sub,:]))



### Prepare data for boxplots
box_data = (val=[vec(fut_hist),vec(fut_nf_rcp45),vec(fut_nf_rcp85),vec(fut_ff_rcp45),vec(fut_ff_rcp85),vec(fut_hist[mam_cesm_sub,:]),vec(fut_nf_rcp45[mam_cesm_sub,:]),vec(fut_nf_rcp85[mam_cesm_sub,:]),vec(fut_ff_rcp45[mam_cesm_sub,:]),vec(fut_ff_rcp85[mam_cesm_sub,:]),vec(fut_hist[jja_cesm_sub,:]),vec(fut_nf_rcp45[jja_cesm_sub,:]),vec(fut_nf_rcp85[jja_cesm_sub,:]),vec(fut_ff_rcp45[jja_cesm_sub,:]),vec(fut_ff_rcp85[jja_cesm_sub,:])],
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

fig1
save("/home/cschmidt/projects/attaino3/plots/PUB/fig13_box_hist_future_comp_CAMX.svg",fig1)
save("/home/cschmidt/projects/attaino3/plots/PUB/fig13_box_hist_future_comp_CAMX.png",fig1)

#### Densities exceedances
fut_hist =  readdlm("data/biascorr/HC2007t16-WC-CESM-Cam-TNO3_mda8O3_lonlat_bias_cor_bcstations.csv", ',',skipstart=1)[:,2:end]
fut_ff_rcp45 = readdlm("data/biascorr/camx/camx_45_ff_bcstations.csv", ',',skipstart=1)[:,2:end]
fut_nf_rcp45 = readdlm("data/biascorr/camx/camx_45_nf_bcstations.csv" , ',',skipstart=1)[:,2:end]
fut_ff_rcp85 = readdlm("data/biascorr/camx/camx_85_ff_bcstations.csv", ',',skipstart=1)[:,2:end]
fut_nf_rcp85 = readdlm("data/biascorr/camx/camx_85_nf_bcstations.csv", ',',skipstart=1)[:,2:end]

fut_hist_exc = ifelse.(fut_hist .> 120, 1,0)
fut_ff_rcp45_exc = ifelse.(fut_ff_rcp45 .> 120, 1,0)
fut_nf_rcp45_exc = ifelse.(fut_ff_rcp85 .> 120, 1,0)
fut_nf_rcp85_exc = ifelse.(fut_nf_rcp85 .> 120, 1,0)
fut_ff_rcp85_exc = ifelse.(fut_ff_rcp85 .> 120, 1,0)


mam_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10 - 10,mean(sum(ifelse.(fut_nf_rcp85[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[mam_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[mam_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[mam_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)

jja_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10 - 10,mean(sum(ifelse.(fut_nf_rcp85[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[jja_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[jja_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[jja_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


son_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_hist[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10 - 3,mean(sum(ifelse.(fut_nf_rcp85[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45[son_cesm_sub,:] .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc[son_cesm_sub,:],dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85[son_cesm_sub,:] .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


ally_vals = (cat = [1,1,2,2,3,3,4,4,5,5],
    val=[mean(sum(fut_hist_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_hist .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp45_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_nf_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_nf_rcp85_exc,dims=1)[:])./10 - 25,mean(sum(ifelse.(fut_nf_rcp85 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp45_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp45 .> 100,1,0),dims=1))./10,mean(sum(fut_ff_rcp85_exc,dims=1)[:])./10,mean(sum(ifelse.(fut_ff_rcp85 .> 100,1,0),dims=1))./10],
    stgrp=[1,1,2,2,3,3,4,4,5,5],
    colgroup=[1,2,1,2,1,2,1,2,1,2],
    col=[bcols[1],darken(bcols[2],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2),bcols[2],darken(bcols[2],1.2),bcols[3],darken(bcols[3],1.2)]
)


darken(bcols[1],1.1)

ally_vals.val


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

subtract_odd_from_even_keep_odd(ally_vals.val)

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
save("/home/cschmidt/projects/attaino3/plots/PUB/fig14_future_exc_bar_mam_jja_son_CAMX.svg",fig2)
save("/home/cschmidt/projects/attaino3/plots/PUB/fig14_future_exc_bar_mam_jja_son_CAMX.png",fig2)

fig2