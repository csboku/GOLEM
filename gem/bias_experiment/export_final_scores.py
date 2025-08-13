"""
Calculates and exports the final cross-validation RMSE scores to a JSON file.
This version includes the Machine Learning method with the corrected, robust logic.
"""
import xarray as xr
import numpy as np
import pandas as pd
from scipy.stats import norm, gamma
from scipy.interpolate import Rbf
from sklearn.ensemble import RandomForestRegressor
import config
import warnings
import json
import os

warnings.filterwarnings("ignore", category=RuntimeWarning)

# --- Helper Functions ---
def get_model_data_at_stations(data, locs):
    coords = xr.DataArray(list(locs.values()), dims=("station", "coord"), coords={"station": list(locs.keys()), "coord": ["x", "y"]})
    return data.sel(x=coords.sel(coord="x"), y=coords.sel(coord="y"), method="nearest")
def calculate_rmse(pred, act): return np.sqrt(((pred - act) ** 2).mean()).item()
def toTitleCase(s): return s.replace("_", " ").title()

# --- Correction Methods (simplified for CV) ---
def scaling_correction(data, obs, model): return data * (obs.mean() / model.mean())
def delta_change_correction(data, obs, model): return data + (obs.mean() - model.mean())
def variance_scaling_correction(data, obs, model): return (data - model.mean()) * (obs.std() / model.std()) + obs.mean()
def quantile_mapping_correction(data, obs, model):
    mq = np.quantile(model.values.flatten(), np.linspace(0, 1, 100))
    oq = np.quantile(obs.values.flatten(), np.linspace(0, 1, 100))
    return data.copy(data=np.interp(data.values.flatten(), mq, oq).reshape(data.shape))
def parametric_mapping_correction(data, obs, model):
    om, os = norm.fit(obs.values.flatten())
    mm, ms = norm.fit(model.values.flatten())
    return data.copy(data=norm.ppf(norm.cdf(data, loc=mm, scale=ms), loc=om, scale=os))
def parametric_mapping_gamma_correction(data, obs, model):
    of = gamma.fit(obs.values.flatten())
    mf = gamma.fit(model.values.flatten())
    return data.copy(data=gamma.ppf(gamma.cdf(data, a=mf[0], loc=mf[1], scale=mf[2]), a=of[0], loc=of[1], scale=of[2]))
def spatial_delta_correction(data, obs, model, locs):
    delta = obs.mean(dim="time") - model
    sx, sy = [loc[0] for loc in locs.values()], [loc[1] for loc in locs.values()]
    rbfi = Rbf(sx, sy, delta.values, function='linear')
    gx, gy = np.meshgrid(data.x.values, data.y.values)
    return data + rbfi(gx, gy)
def ml_correction(data, train_obs, model_at_train, train_locs):
    df_train = train_obs.to_dataframe(name='y_true').reset_index()
    biased_map = model_at_train.to_dataframe(name='y_biased')['y_biased'].to_dict()
    df_train['y_biased'] = df_train['station'].map(biased_map)
    coords_df = pd.DataFrame.from_dict(train_locs, orient='index', columns=['x', 'y'])
    df_train = df_train.merge(coords_df, left_on='station', right_index=True).dropna()
    
    rf = RandomForestRegressor(n_estimators=50, random_state=42, n_jobs=-1, min_samples_leaf=5)
    rf.fit(df_train[['y_biased', 'x', 'y']], df_train['y_true'])
    
    df_pred = data.to_dataframe(name='y_biased').reset_index()
    predictions = rf.predict(df_pred[['y_biased', 'x', 'y']])
    return data.copy(data=predictions.reshape(data.shape))

def main():
    all_station_data = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]
    model_1km_data = xr.open_dataset("ds_1km.nc")[config.VARIABLE_NAME]
    
    methods = {
        "scaling": scaling_correction, "delta": delta_change_correction,
        "variance": variance_scaling_correction, "qm": quantile_mapping_correction,
        "parametric": parametric_mapping_correction, "parametric_gamma": parametric_mapping_gamma_correction,
        "spatial_delta": spatial_delta_correction, "ml": ml_correction
    }
    
    results = {name: [] for name in methods}; results["original"] = []
    station_names = list(config.STATION_LOCATIONS.keys())

    for val_station_name in station_names:
        print(f"  - Cross-validation run, holding out: {val_station_name}")
        train_locs = {s: config.STATION_LOCATIONS[s] for s in station_names if s != val_station_name}
        val_loc = {val_station_name: config.STATION_LOCATIONS[val_station_name]}
        train_obs = all_station_data.sel(station=list(train_locs.keys()))
        val_obs_actual = all_station_data.sel(station=val_station_name)
        model_at_train = get_model_data_at_stations(model_1km_data, train_locs)
        model_at_val = get_model_data_at_stations(model_1km_data, val_loc)
        
        # Compare against the mean of the validation station's time series
        results["original"].append(calculate_rmse(model_at_val, val_obs_actual.mean(dim="time")))

        for name, func in methods.items():
            if name in ["spatial_delta", "ml"]:
                corrected_grid = func(model_1km_data, train_obs, model_at_train, train_locs)
            else:
                corrected_grid = func(model_1km_data, train_obs.stack(all_obs=("station", "time")), model_at_train)
            
            predicted_value = get_model_data_at_stations(corrected_grid, val_loc)
            results[name].append(calculate_rmse(predicted_value, val_obs_actual.mean(dim="time")))

    final_scores = {toTitleCase(name): f"{np.mean(rmse_list):.2f}" for name, rmse_list in results.items()}
    final_scores["Stations (Observed)"] = "N/A"
    
    filepath = os.path.join("web/data", "scores.json")
    with open(filepath, 'w') as f: json.dump(final_scores, f, indent=4)
    print(f"Successfully exported RMSE scores to {filepath}")

if __name__ == "__main__":
    main()