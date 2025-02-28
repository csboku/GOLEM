##########Fix missing columns in district
setwd("~/projects/attaino3/repos/attain_paper/code/shp_mapping_terra/repair")


datadir <- "/home/cschmidt/data/attain/shp_mapped/county_mapped/mda8/"

inp_files <- list.files(datadir)
inp_f <- list.files(datadir,full.names = T)
inp_f

##### Benutze apply statt mean
i=57
floor(apply(csvin[c(i-2,i-1,i+1,i+2)], 1, mean,na.rm=T))

csvin <- read.csv(inp_f[1])
all_miss <- apply(csvin, 2, function(x) all(is.na(x)))
missing_cols <- which(all_miss==T)

for(f in c(1:length(inp_f))){
    print(f)
    csvin <- read.csv(inp_f[f])
  
    for(i in c(1:length(missing_cols))){

        csvin[,missing_cols[i]] <- apply(csvin[,missing_cols[i]-2:missing_cols[i]+2], 1, mean,na.rm=T)
        
    }
    write.csv(csvin,inp_f[f],row.names=F)
}


##### Für exc districts muss anhand von der spalten gerechnet werden

#ROHRBACH COL 57

datadir <- "/home/cschmidt/data/attain/shp_mapped/county_mapped/exc"

inp_files <- list.files(datadir)
inp_f <- list.files(datadir,full.names = T)
inp_f


for(f in c(1:length(inp_f))){
    print(f)
    csvin <- read.csv(inp_f[f])

    for(i in c(1:length(missing_cols))){
      
      csvin[,missing_cols[i]] <- floor(apply(csvin[,missing_cols[i]-2:missing_cols[i]+2], 1, mean,na.rm=T))
      
    }
        
    write.csv(csvin,inp_f[f],row.names=F)
}

###### Delete double index col

for(f in c(1:length(inp_f))) {
  csvin <- read.csv(inp_f[f])
  csvin <- csvin[,-1]
  write.csv(csvin,inp_files[f],row.names = F)
}

###### Fix dates district files





