using NCDatasets, Statistics, Plots, RollingFunctions

ncin = Dataset("/home/cschmidt/data/att_chchem/otudiff.nc")


hno_diff = ncin["hno3"][:,:,1,:]
ho_diff = ncin["ho2"][:,:,1,:]
hch0_diff = ncin["hcho"][:,:,1,:]
htwootwo_diff = ncin["h2o2"][:,:,1,:]


hno_diff


plot(rollmean(mean(hno_diff,dims=[1,2])[:],500))
plot!(rollmean(mean(ho_diff,dims=[1,2])[:],500))
plot!(rollmean(mean(hch0_diff,dims=[1,2])[:],500))
plot!(rollmean(mean(htwootwo_diff,dims=[1,2])[:],500))
xlims!(1095,2800)

