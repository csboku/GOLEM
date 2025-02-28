#####Fix missing columns in district
setwd("~/projects/attaino3/repos/attain_paper/code/shp_mapping_terra/")

datadir <- "/home/cschmidt/data/attain/SOMO35_ppb_days/csv"

inp_files <- list.files(datadir)
inp_f <- list.files(datadir,full.names = T)

for(f in c(1:length(inp_f))){
    
    csvin <- read.csv(inp_f[f])
    all_miss <- apply(csvin, 2, function(x) all(is.na(x)))
    missing_cols <- which(all_miss==T)

    for(i in c(1:length(missing_cols))){

        csvin[,missing_cols[i]] <- (csvin[,missing_cols[i]-1]+csvin[,missing_cols[i]+1])/2
        
    }
    write.csv(csvin,inp_files[f])
}
