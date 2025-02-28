


`%nin%` = Negate(`%in%`)

ref_csv <- read.csv("/home/cschmidt/data/attain_future_csv/att_bias_wrf_cesm_hist_statmatch.csv")
ref_csv_exc <- read.csv("/home/cschmidt/data/attain_future_csv/att_bias_wrf_cesm_hist_statmatch.csv")

testfur <- read.csv("/home/cschmidt/data/attain_future_csv/rcp45_FF_wrf_corr.csv")



dim(ref_csv)
dim(testfur)

fut_csv <- list.files("/home/cschmidt/data/attain_future_csv",full.names = T,pattern = "rcp")

testfut <- read.csv(fut_csv[1])
dim(testfut)

naref <- colSums(is.na(ref_csv))
nafut <- colSums(is.na(testfut))

names(which(naref > 0))
names(which(nafut > 0))

nacols = c(names(which(naref > 0)),names(which(nafut > 0)))


rmcols <- unique(nacols)


colnames(ref_csv)
colnames(testfut)

keepind <- which(colnames(testfut) %in% colnames(ref_csv))

keepind

dim(testfut[,keepind])

for(i in c(1:length(fut_csv))){

    futdat <- read.csv(fut_csv[i])
    write.csv(futdat[,keepind],paste0(substr(fut_csv[i],1,nchar(fut_csv[i])-4),"_corr.csv"),row.names=F)
}


ref_csv

ref_csv <- read.csv("/home/cschmidt/data/attain_future_csv/att_bias_wrf_cesm_hist_statmatch.csv")
write.csv(ref_csv[,which(colnames(ref_csv) %in% colnames(testfur))],"/home/cschmidt/data/attain_future_csv/att_bias_wrf_cesm_hist_statmatch_corr.csv",row.names=F)


ref_csv <- read.csv("/home/cschmidt/data/attain_future_csv/att_bias_wrf_cesm_hist_statmatch_corr.csv")
dim(ref_csv)
