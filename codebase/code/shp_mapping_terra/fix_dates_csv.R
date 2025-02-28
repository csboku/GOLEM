library(ncdf4)
library(lubridate)
library(PCICt)

csvdata <- "~/data/attain/shp_mapped/district_mapped/exc/"

ncdata <- "~/data/attain/bias_corr_output_exc/"


csv_f <- list.files(csvdata,full.names = T)
nc_f <- list.files(ncdata,full.names = T)

csv_f
nc_f

idx=10
csv_f[idx]

ncin <- nc_open(nc_f[idx])

nctime <- ncvar_get(ncin,"time")

nctime_att <- ncatt_get(ncin,"time")
nctime_att
or  <- substr(nctime_att$units,15,24)

as.PCICt(nctime*60*24,cal = "noleap",origin = or, format="%d%m%Y")

input_date <- as.Date(as.POSIXct(nctime*60*24,origin = or))
input_date <- as.PCICt(nctime*60*24,cal = "noleap",origin = or, format="%d%m%Y")

head(input_date)
tail(input_date)

csv_in <- read.csv(csv_f[idx])

csv_in$date <- input_date

write.csv(csv_in,csv_f[idx],row.names = F)

######## Copy dates from distric files to county files

dist_dir <- "~/data/attain/shp_mapped/district_mapped/exc/"
coun_dir <- "~/data/attain/shp_mapped/county_mapped/exc/"

dist_f <- list.files(dist_dir,full.names = T)
coun_f <- list.files(coun_dir,full.names = T)

d_csv <- read.csv(dist_f[1])
c_csv <- read.csv(coun_f[1])

c_csv$date == d_csv$date

for (i in c(1:length(dist_f))) {
  print(i)
  d_csv <- read.csv(dist_f[i])
  c_csv <- read.csv(coun_f[i])
  
  c_csv$date <- d_csv$date
  
  write.csv(c_csv,coun_f[i],row.names = F)
}




