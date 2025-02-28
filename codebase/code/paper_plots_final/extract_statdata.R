library(terra)

setwd("/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/model_comp_final")

station_data <- read.csv("./data/old/aut_sites_meta_utf.csv",dec = ".", sep = ",")

station_data <- station_data[order(station_data$station_european_code),]

### Filter out unneeded stations
station_data <- station_data[station_data["Hoehe"] < 1500,]
station_data <- station_data[station_data["type_of_station"]  == "Background",]

#### Get NA fractions
meas_aut <- read.csv("./data/old/o3_mda8_1990-2019_AT_mug.csv")

#### Sort by date
meas_date <- as.Date(meas_aut$date)

meas_aut <- meas_aut[which(meas_date >= as.Date("2007-01-01") & meas_date <= as.Date("2016-12-31")),]

meas_date <- as.Date(meas_aut$date)

meas_aut <- meas_aut[,-1]

meas_aut <- meas_aut[,order(colnames(meas_aut))]

meas_aut <- meas_aut[,which(colnames(meas_aut) %in% unname(unlist(station_data["station_european_code"])))]

##### Remove meas rowd
station_data <- station_data[which(unname(unlist(station_data["station_european_code"])) %in% colnames(meas_aut)),]



dim(station_data)
dim(meas_aut)

### Remove NAs
meas_aut <- meas_aut[,colSums(is.na(meas_aut)) / dim(meas_aut)[1] < 0.1]

station_data <- station_data[which(unname(unlist(station_data["station_european_code"])) %in% colnames(meas_aut)),]


meas_aut <- cbind(date = meas_date,meas_aut)

write.csv(meas_aut,"./data/meas/attain_meas_mda8_bcstations.csv",row.names=FALSE)
write.csv(station_data,"./data/meas/attain_station_meta_bcstations.csv",row.names=FALSE)

######### Now we ectract the data 
station_data$LAENGE
station_data$BREITE

bias_files <- list.files("/gpfs/data/fs71391/cschmidt/lenian/data/attain/bias_corr_output_mda8",pattern = ".nc")
bias_f <- list.files("/gpfs/data/fs71391/cschmidt/lenian/data/attain/bias_corr_output_mda8",pattern = ".nc",full.names = TRUE)



paste0(substr(bias_files[1],1,nchar(bias_files[1] )-3),"_bcstations.csv")


for(i in c(1:length(bias_f))){
    rast_in <- rast(bias_f[i])
    out <- t(extract(rast_in,cbind(station_data$LAENGE,station_data$BREITE),method="bilinear"))
    colnames(out) <- station_data$station_european_code
    write.csv(out,paste0("./data/biascorr/",substr(bias_files[i],1,nchar(bias_files[i] )-3),"_bcstations.csv"))

}

###### For the raw model data
bias_files <- list.files("/gpfs/data/fs71391/cschmidt/lenian/data/attain/model_output",pattern = ".nc")
bias_f <- list.files("/gpfs/data/fs71391/cschmidt/lenian/data/attain/model_output",pattern = ".nc",full.names = TRUE)

bias_files


paste0(substr(bias_files[1],1,nchar(bias_files[1] )-3),"_bcstations.csv")


for(i in c(1:length(bias_f))){
    rast_in <- rast(bias_f[i])
    out <- t(extract(rast_in,cbind(station_data$LAENGE,station_data$BREITE),method="bilinear"))
    colnames(out) <- station_data$station_european_code
    write.csv(out,paste0("./data/model/",substr(bias_files[i],1,nchar(bias_files[i] )-3),"_bcstations.csv"))

}

dim(out)



###### For the CAMx biascorr

camx_files <- list.files("/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/paper_plots_final/data/raw_files",pattern = ".nc")
camx_f <- list.files("/sto2/data/lenian/projects/attaino3/repos/attain_paper/code/paper_plots_final/data/raw_files",pattern = ".nc",full.names = TRUE)

camx_files




for(i in c(1:length(camx_f))){
    rast_in <- rast(camx_f[i])
    out <- t(extract(rast_in,cbind(station_data$LAENGE,station_data$BREITE),method="bilinear"))
    colnames(out) <- station_data$station_european_code
    write.csv(out,paste0("./data/biascorr/camx/",substr(camx_files[i],1,nchar(camx_files[i] )-3),"_bcstations.csv"))

}
    
rast_in <- rast(camx_f[1])

out <- extract(rast_in,cbind(station_data$LAENGE,station_data$BREITE),method="bilinear")
