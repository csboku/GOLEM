using NCDatasets, Statistics,CFTime


graz_fine = Dataset("/media/cschmidt/platti_ssd/data/future_capacity/wrfchem/o3_graz/hist_cesm_2011_1km_graz_masked_smooth.nc")
graz_coarse = Dataset("/media/cschmidt/platti_ssd/data/future_capacity/wrfchem/o3_graz_9km/hist_cesm_2011_graz.nc")

ds_time = graz_fine["time"][:]

month(ds_time)


month_sub = CFTime.month.(ds_time) .== 7

size(graz_fine["O3"])


graz_fine_o3 = graz_fine["O3"][:,:,month_sub]
graz_coarse_o3 = graz_coarse["O3"][:,:,month_subs]