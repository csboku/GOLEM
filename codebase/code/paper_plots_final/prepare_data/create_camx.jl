using NCDatasets,Statistics,CairoMakie

cd(@__DIR__)

datadir = "/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/paper_plots_final/data/bc_hourly_rast"

inp_files = readdir(datadir)

