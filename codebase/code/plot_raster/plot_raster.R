library(terra)

datadir <- "~/data/attain/bias_corr_output_mda8/seamean/"

setwd(datadir)

inp_f <- list.files(datadir,full.names = T)
inp_files <- list.files(datadir,full.names = F)


### Create finer grid dataset
for (i in c(1:length(inp_f))) {
  print(i)
  ncin <- rast(inp_f[i])
  ncin_dis <- disagg(ncin,fact=c(6),method="bilinear",filename=paste0("n5_",inp_files[i]),overwrite=T)
}


