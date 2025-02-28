setwd("/home/cschmidt/projects/attaino3/repos/attain_paper")

###### Remove missing cols and rows 

att_mod_wrf <- read.csv("/home/cschmidt/data/measmod_csv/att_bias_camx_cesm_hist_statmatch.csv")

apply(att_mod_wrf,2,is.na)

att_na_colsum <- colSums(is.na(att_mod_wrf))

which(att_na_colsum > 1)


