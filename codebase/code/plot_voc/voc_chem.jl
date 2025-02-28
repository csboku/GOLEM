using NCDatasets,Statistics,Plots

cd(@__DIR__)


datadir = "/home/cschmidt/data/attain_allvar_monmean/rcp45_2046t55"

chem_f = readdir(datadir,join=true)

rcp45_ff_chem = Dataset(chem_f[3])

keys(rcp45_ff_chem) |> print

rcp45_ff_nox = rcp45_ff_chem["no"][:,:,1,:]+rcp45_ff_chem["no2"][:,:,1,:]

rcp45_ff_o3 = rcp45_ff_chem["o3"][:,:,1,:]

rcp45_ff_voc = rcp45_ff_chem["orgaro1i"][:,:,1,:] +rcp45_ff_chem["orgaro1j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgaro2i"][:,:,1,:] + rcp45_ff_chem["orgaro2j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgalk1i"][:,:,1,:] + rcp45_ff_chem["orgalk1j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgole1i"][:,:,1,:] + rcp45_ff_chem["orgole1j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgba1i"][:,:,1,:] + rcp45_ff_chem["orgba1j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgba2i"][:,:,1,:] + rcp45_ff_chem["orgba2j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgba3i"][:,:,1,:] + rcp45_ff_chem["orgba3j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgba4i"][:,:,1,:] + rcp45_ff_chem["orgba4j"][:,:,1,:]
rcp45_ff_voc = rcp45_ff_voc + rcp45_ff_chem["orgpai"][:,:,1,:] + rcp45_ff_chem["orgpaj"][:,:,1,:]


plot(mean(rcp45_ff_nox,dims=[1,2])[1,1,:])
plot!(mean(rcp45_ff_o3,dims=[1,2])[1,1,:])
plot!(mean(rcp45_ff_voc,dims=[1,2])[1,1,:])


rcp45_ff_nox_mean = mean(rcp45_ff_nox,dims=[1,2])[1,1,:]
rcp45_ff_o3_mean = mean(rcp45_ff_o3,dims=[1,2])[1,1,:]
rcp45_ff_voc_mean = mean(rcp45_ff_voc,dims=[1,2])[1,1,:]
rcp45_ff_ratio_mean = rcp45_ff_nox_mean ./ rcp45_ff_voc_mean



rcp45_ff_nox_mean_norm = rcp45_ff_nox_mean./mean(rcp45_ff_nox_mean)
rcp45_ff_o3_mean_norm = rcp45_ff_o3_mean./mean(rcp45_ff_o3_mean)
rcp45_ff_voc_mean_norm = rcp45_ff_voc_mean./mean(rcp45_ff_voc_mean)

rcp45_ff_rat_norm = rcp45_ff_nox_mean_norm ./ rcp45_ff_voc_mean_norm

plot(rcp45_ff_nox_mean_norm[1:40],label="NOx")
plot!(rcp45_ff_voc_mean_norm[1:40], label = "VOC")
plot!(rcp45_ff_o3_mean_norm[1:40], label = "O3", linewidth=2)
plot!(rcp45_ff_rat_norm[1:40],label="ratio",linestyle=:dash,linewidth=1.5 )
ylabel!("NORMALIZED")
xlabel!("Months")
png("nox_voc_o3.png")

plot(rcp45_ff_ratio_mean[1:50],label = "Ratio")
plot!(rcp45_ff_o3_mean_norm[1:50], label = "O3", linewidth=2)

cor(rcp45_ff_rat_norm,rcp45_ff_o3_mean_norm)

