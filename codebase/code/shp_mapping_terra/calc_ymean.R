


###### Calculate yearly mean for Exceedances on the district
setwd("~/projects/attaino3/repos/attain_paper/code/shp_mapping_terra/")

datadir <- "~/data/attain/shp_mapped_spatial/district_mapped/exc/"

inp_f <- list.files(datadir,full.names = T)
inp_files <- list.files(datadir,full.names = F)

inp_files
csvin <- read.csv(inp_f[1])

csvin$date <- as.Date(csvin$date)

year <- format(csvin$date, format="%Y")

csv_out <- aggregate(csv_in[,-c(1,2)],by = list(year), FUN = sum)

for (i in c(1:length(inp_f))) {
  csvin <- read.csv(inp_f[i])
  csvin$date <- as.Date(csvin$date)
  year <- format(csvin$date, format="%Y")
  csv_out <- aggregate(csvin[,-c(1)],by = list(year), FUN = sum)
  write.csv(csv_out,paste0(substr(inp_files[i],1,nchar(inp_files[i])-4),"_ymean.csv"),row.names = F)
}
#### Version for other date colname 
for (i in c(1:length(inp_f))) {
  csvin <- read.csv(inp_f[i])
  csvin$Date <- as.Date(csvin$Date)
  year <- format(csvin$Date, format="%Y")
  csv_out <- aggregate(csvin[,-c(1)],by = list(year), FUN = sum)
  write.csv(csv_out,paste0(substr(inp_files[i],1,nchar(inp_files[i])-4),"_ymean.csv"),row.names = F)
}

#### Repair file at index 7
csv_in <- read.csv(inp_f[7])
csv_in2 <- read.csv(inp_f[9])
csv_in$date <- csv_in2$date

write.csv(csv_in,inp_f[7],row.names = F)



inp_f[7]
inp_f[9]
