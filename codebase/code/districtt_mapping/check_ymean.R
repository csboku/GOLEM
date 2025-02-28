

datadir <- "~/data/attain/district_mapped/ymean/"

input_files <- list.files(datadir,full.names = T)

csv_in <- read.csv(input_files[1])

plot(csv_in[,3],type="l",ylim = c(0,10))
lines(csv_in[,4],type="l",ylim = c(0,10),col = "red")

