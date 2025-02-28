library(terra)

datadir_mda <- "~/data/attain/bias_corr_output_mda8/"

mda_f = list.files(datadir_mda,full.names = T)
mda_files= list.files(datadir_mda,full.names = F)

datadir_exc <- 
