using CSV,DataFrames,CairoMakie,NCDatasets,DelimitedFiles


cd(@__DIR__)
##### Plot densities
meas = DelimitedFiles.readdlm("/home/cschmidt/data/attain/measmod_csv/meas_stat.csv",',',skipstart=2,skipblanks=true)
camx =  DelimitedFiles.readdlm("/home/cschmidt/data/attain/measmod_csv/mod_camx.csv",',')
wrf = DelimitedFiles.readdlm("/home/cschmidt/data/attain/measmod_csv/mod_wrf.csv",',')