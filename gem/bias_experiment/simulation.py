"""
Simulates the datasets for the bias correction experiment, now using
multivariate distributions to create spatially correlated data.
"""

import numpy as np
import xarray as xr
from scipy.stats import skewnorm
from scipy.ndimage import gaussian_filter
import config

def create_grid(resolution):
    """Creates a 2D grid with the given resolution."""
    x = np.arange(config.X_MIN, config.X_MAX, resolution)
    y = np.arange(config.Y_MIN, config.Y_MAX, resolution)
    return x, y

def generate_normal_dataset(x, y, mean=60, std=5, sigma=1.0):
    """
    Generates a spatially correlated dataset with a normal distribution.
    """
    # 1. Create white noise
    white_noise = np.random.randn(len(y), len(x))
    # 2. Apply Gaussian filter to create spatial correlation
    correlated_noise = gaussian_filter(white_noise, sigma=sigma)
    # 3. Scale to desired mean and standard deviation
    data = mean + (correlated_noise * std)
    
    da = xr.DataArray(data, dims=("y", "x"), coords={"y": y, "x": x}, name=config.VARIABLE_NAME)
    da.attrs["units"] = config.VARIABLE_UNIT
    return da

def generate_bimodal_dataset(x, y, mean1=52, std1=2, mean2=62, std2=2, sigma=4.0):
    """
    Generates a realistic, spatially correlated bimodal distribution.
    """
    # 1. Create a smooth "base" field that will control the state
    base_field = gaussian_filter(np.random.randn(len(y), len(x)), sigma=sigma)
    
    # 2. Create the component distributions
    dist1 = np.random.normal(mean1, std1, size=(len(y), len(x))) # Main, low peak
    dist2 = np.random.normal(mean2, std2, size=(len(y), len(x))) # Secondary, high peak
    dist_bridge = np.random.normal(57, 4, size=(len(y), len(x))) # Bridge distribution

    # 3. Define thresholds using percentiles for consistent mixing
    # This gives us 55% for the low peak, 35% for the high peak, and 10% for the bridge
    threshold1 = np.percentile(base_field, 55)
    threshold2 = np.percentile(base_field, 90) # 55 + 35 = 90

    # 4. Mix the distributions based on the smooth field
    data = np.zeros_like(base_field)
    # Where the base field is lowest, draw from the low peak
    data[base_field <= threshold1] = dist1[base_field <= threshold1]
    # Where the base field is in the middle, draw from the high peak
    data[(base_field > threshold1) & (base_field <= threshold2)] = dist2[(base_field > threshold1) & (base_field <= threshold2)]
    # Where the base field is highest, draw from the bridge to create smooth transitions
    data[base_field > threshold2] = dist_bridge[base_field > threshold2]
    
    da = xr.DataArray(data, dims=("y", "x"), coords={"y": y, "x": x}, name=config.VARIABLE_NAME)
    da.attrs["units"] = config.VARIABLE_UNIT
    return da

def generate_station_data():
    """
    Generates measurement station data with unique, skewed distributions.
    """
    n_timesteps = 1000
    station_names = list(config.STATION_LOCATIONS.keys())
    # Dynamically generate parameters for each station
    np.random.seed(42) # for reproducibility
    station_params = []
    for i in range(config.N_STATIONS):
        params = {
            "a": np.random.uniform(-5, 5),      # Skewness
            "loc": np.random.uniform(55, 65),   # Mean location
            "scale": np.random.uniform(4, 7)    # Standard deviation
        }
        station_params.append(params)

    all_station_data = []
    for params in station_params:
        station_series = skewnorm.rvs(a=params["a"], loc=params["loc"], scale=params["scale"], size=n_timesteps)
        all_station_data.append(station_series)
    return xr.Dataset(
        {config.VARIABLE_NAME: (("station", "time"), np.array(all_station_data))},
        coords={"station": station_names, "time": np.arange(n_timesteps)},
    )

import sys

def main():
    """Main function to generate the datasets."""
    
    # Check for the --stations-only flag
    stations_only = "--stations-only" in sys.argv

    if not stations_only:
        print("Generating all datasets (models and stations)...")
        x_9km, y_9km = create_grid(config.RESOLUTION_9KM)
        x_1km, y_1km = create_grid(config.RESOLUTION_1KM)
        ds_9km = generate_normal_dataset(x_9km, y_9km)
        ds_1km = generate_bimodal_dataset(x_1km, y_1km)
        xr.Dataset({config.VARIABLE_NAME: ds_9km}).to_netcdf("ds_9km.nc")
        xr.Dataset({config.VARIABLE_NAME: ds_1km}).to_netcdf("ds_1km.nc")
    else:
        print("Generating station data only...")

    ds_station = generate_station_data()
    ds_station.to_netcdf("station_data.nc")
    print("Successfully generated station_data.nc")


if __name__ == "__main__":
    main()