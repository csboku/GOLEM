cd(@__DIR__)

Dates_noleap = function(datetime_inp)
    dt_tuple = yearmonthday.(datetime_inp)
    date_out = Date.(getindex.(dt_tuple,1),getindex.(dt_tuple,2),getindex.(dt_tuple,3))
    return(date_out)
end


season_mam = ["March", "April", "May"]
season_jja = ["June", "July", "August"]

s_idx_jja = function(d)
    return(findall(in(season_jja).(monthname.(d))))
end


s_idx_mam = function(d)
    return(findall(in(season_mam).(monthname.(d))))
end

agg_seas_df = function(df)
    mean.(eachcol(df))
end



include("./attain_init.jl")

using RollingFunctions, StatsPlots, RCall

### Measurements/Model comparison Plots

##Read in metadata
meas_meta = CSV.read("./input/meas_meta_rel.csv", DataFrame)
m_height = meas_meta[!,:Hoehe]

### To remove Stations abive 1500m
findall(m_height .> 1500)

att_mod_wrf = CSV.read("/home/cschmidt/data/measmod_csv/att_bias_wrf_cesm_hist_statmatch.csv", DataFrame, missingstring = "NA")
att_mod_camx = CSV.read("/home/cschmidt/data/measmod_csv/att_bias_wrf_cesm_hist_statmatch.csv", DataFrame, missingstring = "NA")

cesm_date_range = DateTimeNoLeap(2007,1,1,) : Day(1) : DateTimeNoLeap(2016,12,31)
cesm_date = collect(cesm_date_range)
cesm_date = Dates_noleap(cesm_date)

att_meas = CSV.read("/home/cschmidt/data/measmod_csv/meas_aut_o3_mda8.csv", DataFrame, missingstring = "NA")

meas_date = att_meas[:,1]

#att_meas = att_meas[:,2:end]

att_mod_wrf_val = Matrix(att_mod_wrf)
att_mod_camx_val = Matrix(att_mod_camx)
att_meas_val = Matrix(att_meas[:,2:end])

#### Calculate which colums have missing variables 
mod_na_cols = findall(sum(ismissing.(att_mod_wrf_val),dims=1).>0)





#ifelse.(a .> 2,1,2)

ifelse.(att_mod_wrf_val.>120,1,0)

### I. Show raw modle output from camx and wrf with measurements and describe the bias correction

## FIG1
# a) Hist exdays 10 Year mean < 1500m
# b) Saame as a) but after the bias correction
# c) Time searies Number of exdays att_hist_rcp26_noattr_o3_ugm3_bias_cor
# d) Boxplot aus a)
# e) Boxplot wie d) aus b)

## FIGS1
# Three selected background stations 
# Annual exdays: a) WRF-Chem vs obs b) CAMx vs obs c) WRF-Chem bias corr vs. obs d) CAMx vs obs 












## FigS2
# 10 Year exdays annual 
# subplot wie S1 a)-d) 
# All year
# MAM
# JJA

## FIG S3
# Wie FIG1 mit CESM und SOCOL


### II Show NOX and CH4 paths 
# Maybe RCP data for Europe?


### III  map differecne plots for all WRF future models

# Plot all models with reference to CESM hist
# RCP2.6 NF FF
# RCP4.5 NF FF
# RCP8.5 NF FF 
# All with relation to hist

# Fig x
