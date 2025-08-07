
import netCDF4 as nc
import numpy as np
import os
import rioxarray
from scipy.ndimage import shift

# --- Configuration ---
NC_FILE_OUT = 'graz_dummy.nc'
CORINE_FILE = 'U2018_CLC2018_V2020_20u1.tif'
LAT_MIN, LAT_MAX, NLAT = 47.0, 47.1, 20
LON_MIN, LON_MAX, NLON = 15.4, 15.5, 20
HOURS = 24
WIND_U = 0.3  # Wind speed in grid cells per hour (east-west)
WIND_V = 0.6  # Wind speed in grid cells per hour (north-south)
GRAZ_DECAY_RATE = 0.08 # Fraction of concentration that decays per hour

# --- CORINE Land Cover Class to Emission Factor Mapping ---
# See https://land.copernicus.eu/user-corner/technical-library/corine-land-cover-nomenclature-guidelines/html
EMISSION_FACTORS = {
    111: 2.5,  # Continuous urban fabric
    112: 1.8,  # Discontinuous urban fabric
    121: 2.0,  # Industrial or commercial units
    122: 1.5,  # Road and rail networks
    141: 0.1,  # Green urban areas
    242: 0.2,  # Coniferous forest
    243: 0.2,  # Mixed forest
    # Add other classes as needed, default is 0
}
DEFAULT_EMISSION = 0.05

# --- Main Script ---
if os.path.exists(NC_FILE_OUT):
    os.remove(NC_FILE_OUT)

# 1. Read and re-grid CORINE data
da_corine = rioxarray.open_rasterio(CORINE_FILE).squeeze()
lat_coords = np.linspace(LAT_MIN, LAT_MAX, NLAT)
lon_coords = np.linspace(LON_MIN, LON_MAX, NLON)
da_regridded = da_corine.rio.reproject_match(da_corine.rio.write_crs("EPSG:4326").rio.set_spatial_dims('x', 'y').rio.write_transform(), crs="EPSG:4326", resampling=5).interp(y=lat_coords, x=lon_coords, method="nearest")
regridded_clc_data = da_regridded.values

# 2. Create emission map from CORINE data
emission_map = np.full((NLAT, NLON), DEFAULT_EMISSION, dtype=np.float32)
for clc_code, emission_factor in EMISSION_FACTORS.items():
    emission_map[regridded_clc_data == clc_code] = emission_factor


with nc.Dataset(NC_FILE_OUT, 'w', format='NETCDF4') as ds:
    # Add some global attributes
    ds.title = 'Graz Chemical Simulation with CORINE Proxy'
    ds.institution = 'Virtual Simulation Inc.'
    ds.source = 'Dummy data generator v6 (CORINE)'
    ds.description = 'A dummy NetCDF file for Graz chemical simulation, using CORINE Land Cover as an emission proxy.'
    ds.history = 'Created ' + np.datetime_as_string(np.datetime64('now'), unit='s')


    # Create dimensions
    ds.createDimension('time', HOURS)
    ds.createDimension('lat', NLAT)
    ds.createDimension('lon', NLON)

    # Create coordinate variables
    times = ds.createVariable('time', 'f8', ('time',))
    lats = ds.createVariable('lat', 'f4', ('lat',))
    lons = ds.createVariable('lon', 'f4', ('lon',))

    # Create the main data variables
    graz_concentration = ds.createVariable('graz_concentration', 'f4', ('time', 'lat', 'lon',))
    precursor_concentration = ds.createVariable('precursor_concentration', 'f4', ('time', 'lat', 'lon',))
    corine_emissions = ds.createVariable('corine_emissions', 'f4', ('lat', 'lon',))


    # Add attributes
    lats.units, lats.long_name = 'degrees_north', 'Latitude'
    lons.units, lons.long_name = 'degrees_east', 'Longitude'
    times.units, times.long_name, times.calendar = f'hours since 2025-08-07 00:00:00', 'Time', 'gregorian'
    graz_concentration.units, graz_concentration.long_name = 'mol m-3', 'Graz Chemical Concentration'
    precursor_concentration.units, precursor_concentration.long_name = 'mol m-3', 'Precursor Chemical Concentration'
    corine_emissions.long_name = 'Emission factors derived from CORINE Land Cover'


    # Write coordinate data
    lats[:], lons[:], times[:] = lat_coords, lon_coords, np.arange(HOURS)
    corine_emissions[:] = emission_map

    # --- Data Generation ---
    # Initialize concentration fields
    prev_precursor = np.zeros((NLAT, NLON))
    prev_graz = np.zeros((NLAT, NLON))

    for i in range(HOURS):
        # Advect previous step's concentrations
        advected_precursor = shift(prev_precursor, (WIND_V, WIND_U), order=1, mode='constant', cval=0)
        advected_graz = shift(prev_graz, (WIND_V, WIND_U), order=1, mode='constant', cval=0)

        # Diurnal variation of emissions
        diurnal_factor = np.exp(-((i - 12)**2) / 50) # General peak around noon
        emissions = emission_map * diurnal_factor

        current_precursor = advected_precursor + emissions + np.random.rand(NLAT, NLON) * 0.02

        # Chemical conversion: precursor -> graz
        conversion_rate = 0.25
        newly_formed_graz = current_precursor * conversion_rate

        # Graz concentration with advection, new formation, and decay
        current_graz = advected_graz + newly_formed_graz
        current_graz *= (1 - GRAZ_DECAY_RATE) # Apply decay

        # Store current state
        precursor_concentration[i, :, :] = current_precursor
        graz_concentration[i, :, :] = current_graz

        # Update previous state for next loop
        prev_precursor = current_precursor
        prev_graz = current_graz

print(f"Successfully created '{NC_FILE_OUT}' using CORINE data.")
