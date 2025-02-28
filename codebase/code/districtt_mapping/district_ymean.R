setwd("~/projects/attaino3/repos/attain_paper/code/districtt_mapping")

datadir <- "~/data/attain/district_mapped/exc/"

inp_file <- list.files(datadir)[1:9]

inp_f <- list.files(datadir, full.names = T)[1:9]

csv_in <- read.csv(inp_f[1])

csv_in <- csv_in[,-1]

csv_in$Date <- as.Date(csv_in$csv_in.Date)

year <- format(csv_in$csv_in.Date, format="%Y")

csv_out <- aggregate(csv_in[,-1],by = list(year), FUN = sum)

colnames(csv_out[,1])

colnames(csv_out)[1] <- "Year"

for (i in c(1:length(inp_f))) {
  print(i)
  csv_in <- read.csv(inp_f[i])
  csv_in$Date <- as.Date(csv_in$Date)
  year <- format(csv_in$Date, format="%Y")
  csv_out <- aggregate(csv_in[,-1],by = list(year), FUN = sum)
  csv_out[,-1] <- csv_out[,-1]/10
  colnames(csv_out)[1] <- "Year"
  write.csv(csv_out, inp_file[i] ,row.names = F)
}

csv_out

plot(csv_out[,3])

csv_out[,3]


####Version for index column
datadir <- "~/data/attain/county_mapped/exc/"

inp_file <- list.files(datadir)

inp_f <- list.files(datadir, full.names = T)

for (i in c(1:length(inp_f))) {
  print(i)
  csv_in <- read.csv(inp_f[i]) 
  csv_in <- csv_in[,-1]
  csv_in$csv_in.Date <- as.Date(csv_in$csv_in.Date)
  year <- format(csv_in$csv_in.Date, format="%Y")
  csv_out <- aggregate(csv_in[,-1],by = list(year), FUN = sum)
  csv_out[,-1] <- csv_out[,-1]/10
  colnames(csv_out)[1] <- "Year"
  write.csv(csv_out, inp_file[i] ,row.names = F)
}

csv_out

plot(csv_out[,3])

csv_out[,3]

