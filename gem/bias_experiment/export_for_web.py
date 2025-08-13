"""
Exports all necessary datasets from NetCDF to a web-friendly JSON format,
including pre-calculated summary statistics (with stations), PDF line data, 
station locations, and global value ranges for consistent color scales.
"""
import xarray as xr
import numpy as np
import json
import os
import config
from scipy.stats import gaussian_kde

def analyze_dataset(data_array):
    finite_values = data_array.values[np.isfinite(data_array.values)]
    if finite_values.size == 0: return {"mean": "NaN", "std_dev": "NaN", "exceedance_pct": "NaN"}
    return {
        "mean": f"{finite_values.mean():.2f}",
        "std_dev": f"{finite_values.std():.2f}",
        "exceedance_pct": f"{np.sum(finite_values > config.THRESHOLD_VALUE) / finite_values.size * 100:.2f}"
    }

def get_pdf_data(data_array):
    values = data_array.values.flatten()
    finite_values = values[np.isfinite(values)]
    if finite_values.size < 2: return {"x": [], "y": []}
    try:
        kde = gaussian_kde(finite_values)
        x_vals = np.linspace(finite_values.min(), finite_values.max(), 200)
        y_vals = kde(x_vals)
        return {"x": x_vals.tolist(), "y": y_vals.tolist()}
    except np.linalg.LinAlgError:
        return {"x": [], "y": []}

def main():
    output_dir = "web/data"
    os.makedirs(output_dir, exist_ok=True)
    print("Exporting all datasets for web dashboard...")

    scenarios = ["1km", "9km"]
    methods = ["original", "scaling", "delta", "variance", "parametric", "parametric_gamma", "qm", "spatial_delta", "ml"]
    all_summaries = {}
    global_ranges = {}

    # --- Station Data ---
    station_data = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]
    station_flat = station_data.stack(all_obs=("station", "time"))
    with open(os.path.join(output_dir, "stations_dist.json"), 'w') as f: json.dump(station_flat.values.tolist(), f)
    with open(os.path.join(output_dir, "stations_pdf.json"), 'w') as f: json.dump(get_pdf_data(station_flat), f)
    with open(os.path.join(output_dir, "station_locations.json"), 'w') as f: json.dump(config.STATION_LOCATIONS, f, indent=4)
    
    # Add station stats to the summary object
    station_summary = analyze_dataset(station_flat)
    for scenario in scenarios:
        if scenario not in all_summaries: all_summaries[scenario] = {}
        all_summaries[scenario]["stations"] = station_summary

    for scenario in scenarios:
        print(f"--- Processing {scenario} scenario ---")
        min_val, max_val = np.inf, -np.inf

        for method in methods:
            filepath = f"ds_{scenario}.nc" if method == "original" else f"corrected_ds_{scenario}_{method}.nc"
            print(f"  - {method}...")
            data_array = xr.open_dataset(filepath)[config.VARIABLE_NAME]
            
            # Filter for finite values for range calculation
            finite_vals = data_array.values[np.isfinite(data_array.values)]
            if finite_vals.size > 0:
                min_val = min(min_val, finite_vals.min())
                max_val = max(max_val, finite_vals.max())

            data_array.to_dataframe().reset_index().rename(columns={'y':'y','x':'x',config.VARIABLE_NAME:'value'}).to_json(os.path.join(output_dir, f"{scenario}_{method}_spatial.json"), orient='records')
            with open(os.path.join(output_dir, f"{scenario}_{method}_dist.json"), 'w') as f: json.dump(data_array.values.flatten().tolist(), f)
            with open(os.path.join(output_dir, f"{scenario}_{method}_pdf.json"), 'w') as f: json.dump(get_pdf_data(data_array), f)
            all_summaries[scenario][method] = analyze_dataset(data_array)
        
        global_ranges[scenario] = {"min": float(min_val) if np.isfinite(min_val) else 0, "max": float(max_val) if np.isfinite(max_val) else 100}

    with open(os.path.join(output_dir, "summary.json"), 'w') as f: json.dump(all_summaries, f, indent=4)
    with open(os.path.join(output_dir, "global_ranges.json"), 'w') as f: json.dump(global_ranges, f, indent=4)

    print("Export complete.")

if __name__ == "__main__":
    main()
