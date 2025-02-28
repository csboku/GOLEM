library(terra)
library(ncdf4)

setwd("~/projects/attaino3/repos/attain_paper/code/shp_mapping_terra/")
#### MDA8 Files
datadir_mda <- "~/data/attain/bias_corr_output_mda8/"

mda_f <- list.files(datadir_mda,full.names = T)
mda_files <- list.files(datadir_mda,full.names = F)

#### EXC Files
datadir_exc <- "~/data/attain/bias_corr_output_exc/"

exc_f <- list.files(datadir_exc,full.names = T)
exc_files <- list.files(datadir_exc,full.names = F)

### Read in shapefiles
shp_district  <- vect("~/data/shp/district_aut_lonlat/district_shp_lonlat.shp")
shp_county <- vect("~/data/shp/county_aut_lonlat/county_shp_lonlat.shp")

shp_county$name


plot(mda_in[[1]])
lines(shp_district)
lines(shp_county[1:1000])
plot(shp_county[1])
mda_in <- rast(mda_f[1])
mda_in[[1]]
#extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
extr_mda_county <- zonal(mda_in,shp_district,fun=mean)

#test <- zonal(mda_in,shp_district,mean)
#tesz <- t(test)

extr_mda_county_df <- as.data.frame(t(extr_mda_county))
rownames(extr_mda_county_df) <- NULL
extr_mda_county_df <-  extr_mda_county_df[-1,]
dim(extr_mda_county_df)
colnames(extr_mda_county_df) <- shp_district$name

#do.call(rbind.data.frame, extr_mda_county)
write.csv(outdf,paste0(substr(mda_files[1],0,nchar(mda_files[1])-3),"_district.csv"),row.names = F)

input_date <- as.Date(time(mda_in)/60/60,origin = "2007-01-01")

outdf <- cbind(date=input_date,extr_mda_county_df)


time(mda_in,tstep="days")
origin(mda_in)


###### MDA( routine )
for (f in c(1:length(mda_f))) {
  print(f)
  mda_in <- rast(mda_f[f])
  
  ncin <- nc_open(mda_f[f])
  nctinfo <- ncatt_get(ncin,"time")
  nc_close(ncin)
  or  <- substr(nctinfo$units,15,24)
  
  #extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
  extr_mda_county <- zonal(mda_in,shp_district,fun=mean)

  extr_mda_county_df <- as.data.frame(t(extr_mda_county))
  rownames(extr_mda_county_df) <- NULL
  #extr_mda_county_df <-  extr_mda_county_df[-1,]
  colnames(extr_mda_county_df) <- shp_district$name
  
  
  input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))

  
  outdf <- cbind(date=input_date,extr_mda_county_df)
  write.csv(outdf,paste0(substr(mda_files[f],0,nchar(mda_files[f])-3),"_district.csv"),row.names = F)
  
}

#### Exceedance routine
for (f in c(1:length(exc_f))) {
  print(f)
  mda_in <- rast(exc_f[f])
  
  ncin <- nc_open(mda_f[f])
  nctinfo <- ncatt_get(ncin,"time")
  nc_close(ncin)
  or  <- substr(nctinfo$units,15,24)
  
  #extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
  extr_mda_county <- zonal(mda_in,shp_district,fun=sum)
  
  extr_mda_county_df <- as.data.frame(t(extr_mda_county))
  rownames(extr_mda_county_df) <- NULL
  #extr_mda_county_df <-  extr_mda_county_df[-1,]
  colnames(extr_mda_county_df) <- shp_district$name
  
  
  #input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))
  input_date <- time(mda_in)
  
  input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))

  outdf <- cbind(date=input_date,extr_mda_county_df)
  write.csv(outdf,paste0(substr(exc_files[f],0,nchar(exc_files[f])-3),"_district.csv"),row.names = F)
  
}

######
###### County Mapping
######


for (f in c(1:length(mda_f))) {
  print(f)
  mda_in <- rast(mda_f[f])
  
  ncin <- nc_open(mda_f[f])
  nctinfo <- ncatt_get(ncin,"time")
  nc_close(ncin)
  or  <- substr(nctinfo$units,15,24)
  
  #extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
  extr_mda_county <- zonal(mda_in,shp_county,fun=mean)
  
  extr_mda_county_df <- as.data.frame(t(extr_mda_county))
  rownames(extr_mda_county_df) <- NULL
  #extr_mda_county_df <-  extr_mda_county_df[-1,]
  colnames(extr_mda_county_df) <- shp_county$name
  
  
  input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))
  
  
  outdf <- cbind(date=input_date,extr_mda_county_df)
  write.csv(outdf,paste0(substr(mda_files[f],0,nchar(mda_files[f])-3),"_county.csv"),row.names = F)
  
}

#### Exceedance routine
for (f in c(1:length(exc_f))) {
  print(f)
  mda_in <- rast(exc_f[f])
  
  ncin <- nc_open(mda_f[f])
  nctinfo <- ncatt_get(ncin,"time")
  nc_close(ncin)
  or  <- substr(nctinfo$units,15,24)
  
  #extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
  extr_mda_county <- zonal(mda_in,shp_county,fun=sum)
  
  extr_mda_county_df <- as.data.frame(t(extr_mda_county))
  rownames(extr_mda_county_df) <- NULL
  #extr_mda_county_df <-  extr_mda_county_df[-1,]
  colnames(extr_mda_county_df) <- shp_county$name
  
  
  #input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))
  input_date <- time(mda_in)
  
  
  outdf <- cbind(date=input_date,extr_mda_county_df)
  write.csv(outdf,paste0(substr(exc_files[f],0,nchar(exc_files[f])-3),"_county.csv"),row.names = F)
  
}
###########
########### TEST
###########
print(1)
mda_in <- rast(exc_f[1])

ncin <- nc_open(mda_f[1])
nctinfo <- ncatt_get(ncin,"time")
nc_close(ncin)
or  <- substr(nctinfo$units,15,24)

#extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
extr_mda_county <- zonal(mda_in,shp_county,fun=sum)

extr_mda_county_df <- as.data.frame(t(extr_mda_county))
rownames(extr_mda_county_df) <- NULL
#extr_mda_county_df <-  extr_mda_county_df[-1,]
colnames(extr_mda_county_df) <- shp_county$name


plot(shp_district[1])

#input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))
input_date <- time(mda_in)


outdf <- cbind(date=input_date,extr_mda_county_df)
write.csv(outdf,paste0(substr(exc_files[f],0,nchar(exc_files[f])-3),"_county.csv"),row.names = F)

shp_county$name |> length()
###### SOMO mapping
datadir_somo <- ""

for (f in c(1:length(mda_f))) {
  print(f)
  mda_in <- rast(mda_f[f])
  
  ncin <- nc_open(mda_f[f])
  nctinfo <- ncatt_get(ncin,"time")
  nc_close(ncin)
  or  <- substr(nctinfo$units,15,24)
  
  #extr_mda_county <- extract(mda_in,shp_district,fun=mean,method=bilinear)
  extr_mda_county <- zonal(mda_in,shp_district,fun=mean)

  extr_mda_county_df <- as.data.frame(t(extr_mda_county))
  rownames(extr_mda_county_df) <- NULL
  #extr_mda_county_df <-  extr_mda_county_df[-1,]
  colnames(extr_mda_county_df) <- shp_district$name
  
  
  input_date <- as.Date(as.POSIXct(time(mda_in)*60,origin = or))

  
  outdf <- cbind(date=input_date,extr_mda_county_df)
  write.csv(outdf,paste0(substr(mda_files[f],0,nchar(mda_files[f])-3),"_district.csv"),row.names = F)
  
}