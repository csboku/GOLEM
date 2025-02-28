######## Read in Data, remove NA's calculate exceedancese
datapath <- "/home/cschmidt/data/measmod_csv/proc"

getwd()
setwd("/home/cschmidt/projects/attaino3/repos/attain_paper/code/meas_model_comp")



csv_files <- list.files(datapath, pattern = "csv")
csv_f <- list.files(datapath, pattern = "csv", full.names = T)
csv_f

#### First select only he considered 65 sations of he bias correction

csv_ref <- read.csv("~/data/measmod_csv/bias_camx.csv")
statnames_keep <- colnames(csv_ref)

csv_in <- read.csv(csv_f[1])
statnames_in <- colnames(csv_in)

csv_out <- csv_in[,which(statnames_in %in% statnames_keep)]
dim(csv_out)
i=3
for(i in c(1:length(csv_f))){
  print(i)
  csv_in <- read.csv(csv_f[i])
  statnames_in <- colnames(csv_in)
  write.csv(csv_in[,which(statnames_in %in% statnames_keep)],paste0(substr(csv_f[i],1,nchar(csv_f[i])-4),"_fin.csv"),row.names=F)
}





calc_ex_thresh_mda8 <- function(df){
    return(sapply(df, function(x) ifelse(x > 120, 1, 0)))
}

#### Claculatet exceedances and write them out
for (i in c(1:5)) {
   csv_in <- read.csv(csv_f[i])
  write.csv(calc_ex_thresh_mda8(csv_in),paste0(substr(csv_f[i],1,nchar(csv_f[i])-4),"_exc.csv"),row.names=F)
}


bias_camx_exc <- read.csv(csv_f[1])
bias_camx <- read.csv(csv_f[2])
bias_wrf_exc <- read.csv(csv_f[3])
bias_wrf <- read.csv(csv_f[4])
meas_aut_exc <- read.csv(csv_f[5])
meas_aut <- read.csv(csv_f[6])
meta_aut <- read.csv(csv_f[7])
mod_camx_exc <- read.csv(csv_f[8])
mod_camx <- read.csv(csv_f[9])
mod_wrf_exc <- read.csv(csv_f[10])
mod_wrf <- read.csv(csv_f[11])


plot(density(apply(meas_aut_exc,2,sum,na.rm=T)),ylim=c(0,0.014))
lines(density(apply(mod_wrf_exc,2,sum,na.rm=T)),col="tomato3")
lines(density(apply(mod_camx_exc,2,sum,na.rm=T)),col="forestgreen")


##### Process new data



