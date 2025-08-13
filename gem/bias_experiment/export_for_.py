"""
Exports all necessary datasets from NetCDF to a web-friendly JSON format,
including pre-calculated summary statistics and PDF line data.
This version is robust to non-finite values in the input data.
"""
import xarray as xr
import numpy as np
import json
import os
import config
from scipy.stats import gaussian_kde

def analyze_dataset(data_array):
    """Calculates key metrics for a single dataset, handling non-finite values."""
    # Ensure we are working with finite values for calculations
    finite_values = data_array.values[np.isfinite(data_array.values)]
    if finite_values.size == 0:
        return {"mean": "NaN", "std_dev": "NaN", "exceedance_pct": "NaN"}

    mean_val = finite_values.mean()
    std_val = finite_values.std()
    exceedance_pct = np.sum(finite_values > config.THRESHOLD_VALUE) / finite_values.size * 100
    return {"mean": f"{mean_val:.2f}", "std_dev": f"{std_val:.2f}", "exceedance_pct": f"{exceedance_pct:.2f}"}

def get_pdf_data(data_array):
    """Calculates the x,y coordinates for a smooth PDF line, handling non-finite values."""
    values = data_array.values.flatten()
    finite_values = values[np.isfinite(values)]
    
    if finite_values.size < 2: # KDE needs at least 2 points
        return {"x": [], "y": []}

    try:
        kde = gaussian_kde(finite_values)
        x_vals = np.linspace(finite_values.min(), finite_values.max(), 200)
        y_vals = kde(x_vals)
        return {"x": x_vals.tolist(), "y": y_vals.tolist()}
    except np.linalg.LinAlgError:
        # This can happen if the data is constant, leading to a singular matrix
        return {"x": [], "y": []}


def main():
    """Main function to run the export for both 1km and 9km scenarios."""
    output_dir = "web/data"
    os.makedirs(output_dir, exist_ok=True)
    print("Exporting all datasets for web dashboard...")

    scenarios = ["1km", "9km"]
    methods = ["original", "scaling", "delta", "variance", "parametric", "parametric_gamma", "qm", "spatial_delta"]
    all_summaries = {}

    # --- Station Data (same for both scenarios) ---
    station_data = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]
    station_flat = station_data.stack(all_obs=("station", "time"))
    with open(os.path.join(output_dir, "stations_dist.json"), 'w') as f:
        json.dump(station_flat.values.tolist(), f)
    with open(os.path.join(output_dir, "stations_pdf.json"), 'w') as f:
        json.dump(get_pdf_data(station_flat), f)

    for scenario in scenarios:
        print(f"--- Processing {scenario} scenario ---")
        all_summaries[scenario] = {}
        for method in methods:
            filepath = f"ds_{scenario}.nc" if method == "original" else f"corrected_ds_{scenario}_{method}.nc"
            print(f"  - {method}...")
            
            data_array = xr.open_dataset(filepath)[config.VARIABLE_NAME]
            
            # Export spatial data
            data_array.to_dataframe().reset_index().rename(columns={'y':'y','x':'x',config.VARIABLE_NAME:'value'}).to_json(os.path.join(output_dir, f"{scenario}_{method}_spatial.json"), orient='records')
            
            # Export raw distribution data (for ECDF)
            with open(os.path.join(output_dir, f"{scenario}_{method}_dist.json"), 'w') as f:
                json.dump(data_array.values.flatten().tolist(), f)
            
            # Export pre-calculated PDF line data
            with open(os.path.join(output_dir, f"{scenario}_{method}_pdf.json"), 'w') as f:
                json.dump(get_pdf_data(data_array), f)
            
            # Store summary stats
            all_summaries[scenario][method] = analyze_dataset(data_array)

    # Export the combined summary statistics
    with open(os.path.join(output_dir, "summary.json"), 'w') as f:
        json.dump(all_summaries, f, indent=4)

    print("Export complete.")

if __name__ == "__main__":
    main()
