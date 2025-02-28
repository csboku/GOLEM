setwd("/home/cschmidt/projects/attaino3/repos/attain_paper/code")

###### Remove missing cols and rows 

csv_path <- "/home/cschmidt/data/attain_future_csv/"

csv_files <- list.files(csv_path,pattern = ".csv")
csv_f <- list.files(csv_path,full.names = T,pattern = ".csv")

threshold <- 0.2



for(i in c(1:length(csv_f))){
    print(csv_files[i])
    csv_in <- read.csv(csv_f[i])
    na_colsum <- colSums(is.na(csv_in))/dim(csv_in)[1]
    
    write.csv(csv_in[,-c(which(na_colsum > threshold))],paste0(substr(csv_f[i],1,nchar(csv_f[i])-4),"_nafix.csv"),row.names=F)
}

## Get all colums with NA

csv_in <- read.csv(csv_f[1])
 
nacol_mod <- which(colSums(is.na(csv_in))>10)

csv_in <- read.csv(csv_f[3])

nacol_meas <- which(colSums(is.na(csv_in))/dim(csv_in)[1] > 0.2)
nacol_meas

nacols <- c(nacol_meas,nacol_mod)
nacols_stations <- names(nacols)
nacols <- unique(nacols)
nacols_stations

write.csv(nacols_stations,"statcodes_na.csv",row.names=F)

####Remove all na stations

for(i in c(1:length(csv_f))){
    print(csv_files[i])
    csv_in <- read.csv(csv_f[i])
    nac_idx <- which(names(csv_in) %in% nacols_stations)    
    
    write.csv(csv_in[,-nac_idx],paste0(substr(csv_f[i],1,nchar(csv_f[i])-4),"_nafix.csv"),row.names=F)
}

#Remove na stations from metadata
meas_meta <- read.csv("./input_measmod/aut_sites_meta_utf.csv")

meas_meta |> colnames()

meas_meta_out <- meas_meta[which(meas_meta$station_european_code %in% nacols_stations),]
meas_meta_out |> dim()

write.csv(meas_meta_out,"metadata_stat_nacorr.csv",row.names=F)

###### Check files 

# csv_files


# csv_in <- read.csv(csv_f[2])

# na_ind <- which(colSums(is.na(csv_in))>10)

# mod_na_stations <- colnames(csv_in)[na_ind]

# csv_in_meas <- read.csv(csv_f[3])
# meas_stations <- colnames(csv_in_meas)



# rmcols_meas <- which(meas_stations %in% mod_na_stations)

# csv_in <- read.csv(csv_f[3])

# csv_out <- csv_in[,-c(rmcols_meas)]

# write.csv(csv_out,csv_f[3],row.names=F)
