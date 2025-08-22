"""
Applies bias correction techniques, including a Machine Learning model
with a robust, time-series-based training approach.
"""
import numpy as np
import xarray as xr
import pandas as pd
from scipy.stats import norm, gamma
from scipy.interpolate import Rbf
from sklearn.ensemble import RandomForestRegressor
import config

# --- Helper Functions ---
def get_model_data_at_stations(data):
    station_coords = xr.DataArray(list(config.STATION_LOCATIONS.values()), dims=("station", "coord"), coords={"station": list(config.STATION_LOCATIONS.keys()), "coord": ["x", "y"]})
    return data.sel(x=station_coords.sel(coord="x"), y=station_coords.sel(coord="y"), method="nearest")

# --- Statistical Methods ---
def scaling_correction(data, obs_data):
    model_at_stations = get_model_data_at_stations(data)
    return data * (obs_data.mean() / model_at_stations.mean())
def delta_change_correction(data, obs_data):
    model_at_stations = get_model_data_at_stations(data)
    return data + (obs_data.mean() - model_at_stations.mean())
def variance_scaling_correction(data, obs_data):
    model_at_stations = get_model_data_at_stations(data)
    obs_mean, obs_std = obs_data.mean(), obs_data.std()
    model_mean, model_std = model_at_stations.mean(), model_at_stations.std()
    return (data - model_mean) * (obs_std / model_std) + obs_mean
def quantile_mapping_correction(data, obs_data):
    model_values = data.values.flatten()
    obs_values = obs_data.values.flatten()
    model_quantiles = np.quantile(model_values, np.linspace(0, 1, 100))
    obs_quantiles = np.quantile(obs_values, np.linspace(0, 1, 100))
    corrected_flat = np.interp(model_values, model_quantiles, obs_quantiles)
    return data.copy(data=corrected_flat.reshape(data.shape))
def parametric_mapping_correction(data, obs_data):
    model_at_stations = get_model_data_at_stations(data)
    obs_mean, obs_std = norm.fit(obs_data.values.flatten())
    model_mean, model_std = norm.fit(model_at_stations.values.flatten())
    model_percentiles = norm.cdf(data, loc=model_mean, scale=model_std)
    return data.copy(data=norm.ppf(model_percentiles, loc=obs_mean, scale=obs_std))
def parametric_mapping_gamma_correction(data, obs_data):
    model_at_stations = get_model_data_at_stations(data)
    obs_fit = gamma.fit(obs_data.values.flatten())
    model_fit = gamma.fit(model_at_stations.values.flatten())
    model_percentiles = gamma.cdf(data, a=model_fit[0], loc=model_fit[1], scale=model_fit[2])
    return data.copy(data=gamma.ppf(model_percentiles, a=obs_fit[0], loc=obs_fit[1], scale=obs_fit[2]))
def spatial_delta_correction(data, obs_data_spatial):
    model_at_stations = get_model_data_at_stations(data)
    delta_at_stations = obs_data_spatial.mean(dim="time") - model_at_stations
    station_x = [loc[0] for loc in config.STATION_LOCATIONS.values()]
    station_y = [loc[1] for loc in config.STATION_LOCATIONS.values()]
    rbfi = Rbf(station_x, station_y, delta_at_stations.values, function='linear')
    grid_x, grid_y = np.meshgrid(data.x.values, data.y.values)
    return data + rbfi(grid_x, grid_y)

# --- Machine Learning Method (Corrected) ---
def ml_correction(data, obs_data_spatial):
    print("  - Training Machine Learning model on full time series...")
    # 1. Prepare Training Data
    model_at_stations = get_model_data_at_stations(data)
    
    # Create a DataFrame for the true observations (5000 rows)
    df_train = obs_data_spatial.to_dataframe(name='y_true').reset_index()
    
    # Map the single biased model value to each of the 1000 time steps for each station
    biased_map = model_at_stations.to_dataframe(name='y_biased')['y_biased'].to_dict()
    df_train['y_biased'] = df_train['station'].map(biased_map)
    
    # Map the coordinates to each row
    coords_df = pd.DataFrame.from_dict(config.STATION_LOCATIONS, orient='index', columns=['x', 'y'])
    df_train = df_train.merge(coords_df, left_on='station', right_index=True).dropna()

    # 2. Train Model
    rf = RandomForestRegressor(n_estimators=50, random_state=42, n_jobs=-1, min_samples_leaf=5)
    rf.fit(df_train[['y_biased', 'x', 'y']], df_train['y_true'])

    # 3. Predict on the full grid
    print("  - Applying model to full grid...")
    df_pred = data.to_dataframe(name='y_biased').reset_index()
    predictions = rf.predict(df_pred[['y_biased', 'x', 'y']])
    
    return data.copy(data=predictions.reshape(data.shape))

def main():
    station_data_timeseries = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]
    station_data_flat = station_data_timeseries.stack(all_obs=("station", "time"))

    corrections = {
        "scaling": scaling_correction, "delta": delta_change_correction,
        "variance": variance_scaling_correction, "qm": quantile_mapping_correction,
        "parametric": parametric_mapping_correction, "parametric_gamma": parametric_mapping_gamma_correction,
        "spatial_delta": spatial_delta_correction, "ml": ml_correction
    }

    for scenario in ["1km", "9km"]:
        print(f"--- Processing {scenario} scenario ---")
        data = xr.open_dataset(f"ds_{scenario}.nc")[config.VARIABLE_NAME]
        for name, func in corrections.items():
            print(f"- Applying {name} correction...")
            if name in ["spatial_delta", "ml"]:
                corrected_data = func(data, station_data_timeseries)
            else:
                corrected_data = func(data, station_data_flat)
            xr.Dataset({config.VARIABLE_NAME: corrected_data}).to_netcdf(f"corrected_ds_{scenario}_{name}.nc")

if __name__ == "__main__":
    main()