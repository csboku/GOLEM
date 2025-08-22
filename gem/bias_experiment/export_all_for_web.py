"""
Exports ALL necessary data for the web dashboard into a single,
consolidated JSON file for robust and simple loading.
This version includes robust data type conversion to prevent JSON errors.
"""
import json
import os
import xarray as xr
import numpy as np
import config
from scipy.stats import gaussian_kde

# Custom JSON encoder to handle NumPy types
class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        return super(NumpyEncoder, self).default(obj)

def analyze_dataset(data_array):
    """Calculates key metrics for a single dataset."""
    finite_values = data_array.values[np.isfinite(data_array.values)]
    if finite_values.size == 0: return {"mean": "NaN", "std_dev": "NaN", "exceedance_pct": "NaN"}
    return {
        "mean": f"{finite_values.mean():.2f}",
        "std_dev": f"{finite_values.std():.2f}",
        "exceedance_pct": f"{np.sum(finite_values > config.THRESHOLD_VALUE) / finite_values.size * 100:.2f}"
    }

def get_pdf_data(data_array):
    """Calculates the x,y coordinates for a smooth PDF line."""
    values = data_array.values[np.isfinite(data_array.values)].flatten()
    if values.size < 2: return {"x": [], "y": []}
    try:
        kde = gaussian_kde(values)
        x_vals = np.linspace(values.min(), values.max(), 200)
        return {"x": x_vals.tolist(), "y": kde(x_vals).tolist()}
    except (np.linalg.LinAlgError, ValueError):
        return {"x": [], "y": []}

def main():
    print("Starting export of all data to a single JSON file...")
    
    station_scenarios = ["3_stations", "10_stations", "25_stations"]
    model_scenarios = ["1km", "9km"]
    methods = ["original", "scaling", "delta", "variance", "qm", "parametric", "parametric_gamma", "spatial_delta", "ml"]
    
    master_data = {}

    for station_scn in station_scenarios:
        print(f"- Processing {station_scn}...")
        master_data[station_scn] = {}
        data_path = os.path.join("web", "data", station_scn)
        
        with open(os.path.join(data_path, "summary.json"), 'r') as f: master_data[station_scn]['summary'] = json.load(f)
        with open(os.path.join(data_path, "scores.json"), 'r') as f: master_data[station_scn]['scores'] = json.load(f)
        with open(os.path.join(data_path, "station_locations.json"), 'r') as f: master_data[station_scn]['locations'] = json.load(f)
        with open(os.path.join(data_path, "global_ranges.json"), 'r') as f: master_data[station_scn]['ranges'] = json.load(f)
        with open(os.path.join(data_path, "stations_pdf.json"), 'r') as f: master_data[station_scn]['stations_pdf'] = json.load(f)

        master_data[station_scn]['model_data'] = {}
        for model_scn in model_scenarios:
            master_data[station_scn]['model_data'][model_scn] = {}
            for method in methods:
                master_data[station_scn]['model_data'][model_scn][method] = {}
                with open(os.path.join(data_path, f"{model_scn}_{method}_pdf.json"), 'r') as f:
                    master_data[station_scn]['model_data'][model_scn][method]['pdf'] = json.load(f)
                with open(os.path.join(data_path, f"{model_scn}_{method}_spatial.json"), 'r') as f:
                    master_data[station_scn]['model_data'][model_scn][method]['spatial'] = json.load(f)

    output_path = os.path.join("web", "data", "data.json")
    with open(output_path, 'w') as f:
        json.dump(master_data, f, cls=NumpyEncoder) # Use the robust encoder
        
    print(f"\nSuccessfully created the consolidated data file: {output_path}")

if __name__ == "__main__":
    main()
