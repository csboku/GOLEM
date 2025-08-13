"""
Performs a leave-one-out cross-validation to quantitatively evaluate bias correction methods.
"""

import xarray as xr
import numpy as np
import pandas as pd
from scipy.stats import norm, gamma
from scipy.interpolate import Rbf
import config
import warnings

# Suppress warnings from fitting, which can happen with few data points
warnings.filterwarnings("ignore", category=RuntimeWarning)

# --- Re-use Correction Functions from bias_correction.py ---

def get_model_data_at_stations(data, station_locations):
    """Extracts model data at specified station locations."""
    station_coords = xr.DataArray(
        list(station_locations.values()),
        dims=("station", "coord"),
        coords={"station": list(station_locations.keys()), "coord": ["x", "y"]},
    )
    return data.sel(
        x=station_coords.sel(coord="x"), y=station_coords.sel(coord="y"), method="nearest"
    )

def scaling_correction(data, obs_data, model_at_stations):
    scaling_factor = obs_data.mean() / model_at_stations.mean()
    return data * scaling_factor

def delta_change_correction(data, obs_data, model_at_stations):
    delta = obs_data.mean() - model_at_stations.mean()
    return data + delta

def variance_scaling_correction(data, obs_data, model_at_stations):
    obs_mean, obs_std = obs_data.mean(), obs_data.std()
    model_mean, model_std = model_at_stations.mean(), model_at_stations.std()
    return (data - model_mean) * (obs_std / model_std) + obs_mean

def quantile_mapping_correction(data, obs_data, model_at_stations):
    model_values = model_at_stations.values.flatten() # Use model data at stations for fitting
    obs_values = obs_data.values.flatten()
    model_quantiles = np.quantile(model_values, np.linspace(0, 1, 100))
    obs_quantiles = np.quantile(obs_values, np.linspace(0, 1, 100))
    corrected_flat = np.interp(data.values.flatten(), model_quantiles, obs_quantiles)
    return data.copy(data=corrected_flat.reshape(data.shape))

def parametric_mapping_correction(data, obs_data, model_at_stations):
    obs_mean, obs_std = norm.fit(obs_data.values.flatten())
    model_mean, model_std = norm.fit(model_at_stations.values.flatten())
    model_percentiles = norm.cdf(data, loc=model_mean, scale=model_std)
    return data.copy(data=norm.ppf(model_percentiles, loc=obs_mean, scale=obs_std))

def parametric_mapping_gamma_correction(data, obs_data, model_at_stations):
    obs_fit_alpha, obs_fit_loc, obs_fit_beta = gamma.fit(obs_data.values.flatten())
    model_fit_alpha, model_fit_loc, model_fit_beta = gamma.fit(model_at_stations.values.flatten())
    model_percentiles = gamma.cdf(data, a=model_fit_alpha, loc=model_fit_loc, scale=model_fit_beta)
    return data.copy(data=gamma.ppf(model_percentiles, a=obs_fit_alpha, loc=obs_fit_loc, scale=obs_fit_beta))

def spatial_delta_correction(data, obs_data_spatial, model_at_stations_spatial, station_locs):
    delta_at_stations = obs_data_spatial.mean(dim="time") - model_at_stations_spatial
    
    station_x = [loc[0] for loc in station_locs.values()]
    station_y = [loc[1] for loc in station_locs.values()]

    rbfi = Rbf(station_x, station_y, delta_at_stations.values, function='linear')
    grid_x, grid_y = np.meshgrid(data.x.values, data.y.values)
    delta_grid = rbfi(grid_x, grid_y)
    
    return data + delta_grid

# --- Main Cross-Validation Logic ---

def calculate_rmse(predicted, actual):
    """Calculates the Root Mean Square Error."""
    return np.sqrt(((predicted - actual) ** 2).mean()).item()

def main():
    """Main function to run the cross-validation."""
    
    all_station_data = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]
    model_1km_data = xr.open_dataset("ds_1km.nc")[config.VARIABLE_NAME]
    
    methods = {
        "scaling": scaling_correction, "delta": delta_change_correction,
        "variance": variance_scaling_correction, "qm": quantile_mapping_correction,
        "parametric": parametric_mapping_correction, "parametric_gamma": parametric_mapping_gamma_correction,
        "spatial_delta": spatial_delta_correction
    }
    
    results = {name: [] for name in methods}
    results["original"] = []

    station_names = list(config.STATION_LOCATIONS.keys())

    for val_station_name in station_names:
        # 1. Split data into training and validation sets
        training_station_names = [s for s in station_names if s != val_station_name]
        
        train_locs = {s: config.STATION_LOCATIONS[s] for s in training_station_names}
        val_loc = {val_station_name: config.STATION_LOCATIONS[val_station_name]}

        train_obs = all_station_data.sel(station=training_station_names)
        val_obs_actual = all_station_data.sel(station=val_station_name)

        # 2. Get model data at station locations
        model_at_train_stations = get_model_data_at_stations(model_1km_data, train_locs)
        model_at_val_station = get_model_data_at_stations(model_1km_data, val_loc)

        # 3. Calculate RMSE for the original, uncorrected model
        original_rmse = calculate_rmse(model_at_val_station, val_obs_actual)
        results["original"].append(original_rmse)

        # 4. Apply each correction method and calculate RMSE
        for name, func in methods.items():
            if name == "spatial_delta":
                corrected_full_grid = func(model_1km_data, train_obs, model_at_train_stations, train_locs)
            else:
                train_obs_flat = train_obs.stack(all_obs=("station", "time"))
                corrected_full_grid = func(model_1km_data, train_obs_flat, model_at_train_stations)
            
            # Get the predicted value at the validation location
            predicted_series = get_model_data_at_stations(corrected_full_grid, val_loc)
            
            rmse = calculate_rmse(predicted_series, val_obs_actual)
            results[name].append(rmse)

    # 5. Average the results and print the summary
    summary = []
    for name, rmse_list in results.items():
        avg_rmse = np.mean(rmse_list)
        summary.append({"Method": name.replace("_", " ").title(), "Average RMSE": f"{avg_rmse:.2f}"})

    df = pd.DataFrame(summary).set_index("Method").sort_values("Average RMSE")

    print("\n" + "="*60)
    print("      Leave-One-Out Cross-Validation Results (1km)")
    print("      (Lower RMSE is better)")
    print("="*60)
    print(df.to_string())
    print("="*60 + "\n")

if __name__ == "__main__":
    main()