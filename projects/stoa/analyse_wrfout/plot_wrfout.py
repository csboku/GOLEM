import xarray as xr
import salem
import xwrf


ds_a = salem.open_wrf_dataset('/home/cschmidt/data/STOA/wrfout/test_run_1/wrfout_d01_2004-06-05_10:00:00')
ds_b = salem.open_wrf_dataset('/home/cschmidt/data/STOA/wrfout/test_run_2/wrfout_d01_2004-06-05_10:00:00')


ds_a['W'].to_netcdf("dsa_W.nc")
ds_b['W'].to_netcdf("dsb_W.nc")



model_levels = ds_a.salem.wrf_zlevel.isel(time=0)
model_levels.to_netcdf("model_levels.nc")

ds_a['Z'].to_netcdf('dsa_Z.nc')
