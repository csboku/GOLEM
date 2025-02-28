using DelimitedFiles,StatsPlots,Statistics,Plots

cd(@__DIR__)
datadir = "/home/cschmidt/data/attain/district_mapped/exc/"

inp_files = readdir(datadir)
inp_f = readdir(datadir,join=true)

idx = 1

inp_files[idx]
csv_in = readdlm(inp_f[idx],',')[2:end,2:end]

exc_sum = vec(sum(csv_in,dims=1)) |> plot

boxplot(exc_sum,label=inp_files[1][1:10])


csv_in


for i in 2:length(inp_f)
   print(i)
   csv_in = readdlm(inp_f[i],',')[2:end,2:end]
   exc_sum = vec(sum(csv_in,dims=1))
   boxplot!(exc_sum,label=(inp_files[i][1:10]))
   println(mean(exc_sum))
end
png("box_ymean.png")

###### Check the county mapped statisitics

datadir_c = "/home/cschmidt/data/attain/county_mapped/ymean/"
inp_f_c = readdir(datadir_c,join=true)
inp_files_c = readdir(datadir_c)

idx=1
csv_in = readdlm(inp_f_c[idx],',')[2:end,3:end]
exc_sum = vec(sum(csv_in,dims=1))
boxplot(exc_sum,label=inp_files_c[1][1:10])
for i in 2:length(inp_f_c)
    print(i)
    csv_in = readdlm(inp_f_c[i],',')[2:end,2:end]
    exc_sum = vec(sum(csv_in,dims=1))
    boxplot!(exc_sum,label=(inp_files_c[i][1:10]))
    println(mean(exc_sum))
 end
 png("box_ymean_c.png")

##### Check the created inp_files

datadir = "/home/cschmidt/data/attain/district_mapped/ymean/"

inp_files = readdir(datadir)
inp_f = readdir(datadir,join=true)

idx = 1

inp_files[idx]
csv_in = readdlm(inp_f[idx],',')[2:end,2:end]

exc_sum = vec(sum(csv_in,dims=1)) |> plot

