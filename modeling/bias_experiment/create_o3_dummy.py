import netCDF4 as nc
import numpy as np
import os
import rioxarray
import xarray as xr
from scipy.ndimage import shift
import argparse

# --- DOMAIN CONFIGURATION ---
GRAZ_LAT_CENTER = 47.07
GRAZ_LON_CENTER = 15.42
DOMAIN_SIZE_KM = 90  # Fixed domain size for all resolutions

# --- FILE CONFIGURATION ---
CORINE_FILE = 'U2018_CLC2018_V2020_20u1.tif'
DEM_FILE = 'dem.tif'

# --- SIMULATION CONFIGURATION ---
HOURS = 24

# --- PROCESS-BASED PROXY MAPPINGS (CLC Code -> Factor) ---
NOX_FACTORS = {
    111: 0.9, 112: 0.7, 121: 1.0, 122: 0.8, "default": 0.05
}
VOC_FACTORS = {
    121: 0.8, 111: 0.5, 112: 0.4, 311: 0.6, 312: 1.0, 313: 0.8, 324: 0.5, "default": 0.1
}
TITRATION_CLASS = 111
TITRATION_FACTOR = 0.6

def create_o3_dummy(resolution_km):
    """
    Generates a process-oriented dummy NetCDF file for O3 concentrations
    over a fixed geographical domain centered on Graz.
    """
    # --- Grid Setup ---
    # Define fixed geographical domain
    domain_deg_lat = DOMAIN_SIZE_KM / 111.32
    domain_deg_lon = DOMAIN_SIZE_KM / (111.32 * np.cos(np.deg2rad(GRAZ_LAT_CENTER)))
    lat_min, lat_max = GRAZ_LAT_CENTER - domain_deg_lat / 2, GRAZ_LAT_CENTER + domain_deg_lat / 2
    lon_min, lon_max = GRAZ_LON_CENTER - domain_deg_lon / 2, GRAZ_LON_CENTER + domain_deg_lon / 2

    # Calculate number of cells based on resolution
    n_cells = int(DOMAIN_SIZE_KM / resolution_km)
    lat_coords = np.linspace(lat_min, lat_max, n_cells)
    lon_coords = np.linspace(lon_min, lon_max, n_cells)
    
    output_filename = f'graz_o3_{resolution_km}km.nc'
    if os.path.exists(output_filename):
        os.remove(output_filename)

    # --- Proxy Data Processing ---
    target_grid = xr.DataArray(
        np.zeros((n_cells, n_cells)),
        coords={'y': lat_coords, 'x': lon_coords},
        dims=('y', 'x')
    ).rio.write_crs("EPSG:4326")

    # 1. Regrid CORINE data
    da_corine = rioxarray.open_rasterio(CORINE_FILE).squeeze()
    regridded_clc = da_corine.rio.reproject_match(target_grid, resampling=5)

    # 2. Create NOx and VOC potential maps
    nox_potential = np.full((n_cells, n_cells), NOX_FACTORS["default"], dtype=np.float32)
    voc_potential = np.full((n_cells, n_cells), VOC_FACTORS["default"], dtype=np.float32)
    for clc_code, factor in NOX_FACTORS.items():
        if clc_code != "default": nox_potential[regridded_clc == clc_code] = factor
    for clc_code, factor in VOC_FACTORS.items():
        if clc_code != "default": voc_potential[regridded_clc == clc_code] = factor

    # 3. Regrid DEM for background O3
    da_dem = rioxarray.open_rasterio(DEM_FILE).squeeze()
    regridded_dem = da_dem.rio.reproject_match(target_grid, resampling=5)
    background_o3 = 35 + 35 * (regridded_dem - regridded_dem.min()) / (regridded_dem.max() - regridded_dem.min())
    background_o3 = background_o3.fillna(35).values

    # --- NetCDF Creation ---
    with nc.Dataset(output_filename, 'w', format='NETCDF4') as ds:
        ds.title = f'Process-Based Dummy O3 Simulation for Graz ({resolution_km}km)'
        ds.domain = f"Fixed {DOMAIN_SIZE_KM}km x {DOMAIN_SIZE_KM}km centered on Graz"

        ds.createDimension('time', HOURS)
        ds.createDimension('lat', n_cells)
        ds.createDimension('lon', n_cells)

        ds.createVariable('lat', 'f4', ('lat',))[:] = lat_coords
        ds.createVariable('lon', 'f4', ('lon',))[:] = lon_coords
        ds.createVariable('regridded_clc', 'i2', ('lat', 'lon',))[:] = regridded_clc.values
        o3_var = ds.createVariable('o3', 'f4', ('time', 'lat', 'lon',))
        o3_var.units = 'ppb'

        # --- Simulation Loop ---
        for i in range(HOURS):
            sunlight = max(0, np.sin((i - 6) * np.pi / 18))
            production = (nox_potential * 0.5 + voc_potential * 0.5) * sunlight * 60
            o3_field = background_o3 + production
            titration_mask = (regridded_clc == TITRATION_CLASS).values
            o3_field[titration_mask] *= (1 - (TITRATION_FACTOR * sunlight))
            o3_var[i, :, :] = o3_field
            
    print(f"Successfully created '{output_filename}' with fixed domain.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate process-based dummy O3 NetCDF files over a fixed domain.")
    parser.add_argument('resolution', type=int, help="Grid resolution in km (e.g., 1 or 9).")
    args = parser.parse_args()
    
    create_o3_dummy(args.resolution)