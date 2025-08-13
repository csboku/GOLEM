"""
Performs and visualizes a temporal analysis at a single grid point.
"""

import xarray as xr
import matplotlib.pyplot as plt
import pandas as pd
import config
import numpy as np

def main():
    """Main function to perform temporal analysis."""
    
    # Location of interest (near station_3)
    target_x = config.STATION_LOCATIONS["station_3"][0]
    target_y = config.STATION_LOCATIONS["station_3"][1]

    # --- Get Station Time Series ---
    station_data = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]
    station_3_series = station_data.sel(station="station_3")

    # --- Get Model Time Series at the chosen point ---
    # We need to simulate a time series for the model data.
    # For this experiment, we'll create a representative time series
    # by taking a slice of the 2D data. A more complex model would have a 3D (y, x, time) array.
    original_1km_data = xr.open_dataset("ds_1km.nc")[config.VARIABLE_NAME]
    # Let's create a plausible time series by taking a diagonal slice and repeating it.
    # This is a simplification to illustrate the method.
    slice_data = np.diag(original_1km_data.sel(x=slice(target_x, None), y=slice(target_y, None)))
    if len(slice_data) < 1000:
        slice_data = np.pad(slice_data, (0, 1000 - len(slice_data)), 'wrap')
    model_series_at_point = xr.DataArray(slice_data[:1000], dims=["time"], coords={"time": station_3_series.time})


    # --- Load all corrected data and get series at the point ---
    corrected_methods = [
        "scaling", "delta", "variance", "parametric", "parametric_gamma", "qm", "spatial_delta"
    ]
    
    corrected_series = {}
    for method in corrected_methods:
        ds = xr.open_dataset(f"corrected_ds_1km_{method}.nc")[config.VARIABLE_NAME]
        # In our simplified case, we apply the same "slicing" to the corrected data
        slice_corr = np.diag(ds.sel(x=slice(target_x, None), y=slice(target_y, None)))
        if len(slice_corr) < 1000:
            slice_corr = np.pad(slice_corr, (0, 1000 - len(slice_corr)), 'wrap')
        corrected_series[method] = xr.DataArray(slice_corr[:1000], dims=["time"], coords={"time": station_3_series.time})


    # --- Plotting ---
    plt.figure(figsize=(20, 10))
    
    # Plot station and original model data
    station_3_series.plot(label="Station 3 (Observed)", color='black', linewidth=2.5)
    model_series_at_point.plot(label="Original Model", color='red', linestyle='--', linewidth=2)

    # Plot corrected series
    for name, series in corrected_series.items():
        series.plot(label=name.replace("_", " ").title(), alpha=0.7, linewidth=1)

    # Plot threshold
    plt.axhline(config.THRESHOLD_VALUE, color="black", linestyle=":", linewidth=2, label=f"Threshold ({config.THRESHOLD_VALUE} {config.VARIABLE_UNIT})")
    
    plt.legend()
    plt.title(f"Time Series Analysis at Grid Point near Station 3 ({target_x}, {target_y})")
    plt.xlabel("Time Step")
    plt.ylabel(f"{config.VARIABLE_NAME} ({config.VARIABLE_UNIT})")
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.savefig("temporal_analysis.png")
    plt.close()

    # --- Quantitative Summary ---
    summary = []
    
    # Original Model
    exceed_orig = (model_series_at_point > config.THRESHOLD_VALUE).sum().item()
    summary.append({"Method": "Original Model", "Days > 70ppm": exceed_orig})
    
    # Station Observations
    exceed_station = (station_3_series > config.THRESHOLD_VALUE).sum().item()
    summary.append({"Method": "Station 3 (Observed)", "Days > 70ppm": exceed_station})

    # Corrected Models
    for name, series in corrected_series.items():
        exceed_corr = (series > config.THRESHOLD_VALUE).sum().item()
        summary.append({"Method": name.replace("_", " ").title(), "Days > 70ppm": exceed_corr})

    df = pd.DataFrame(summary).set_index("Method")
    
    print("\n" + "="*60)
    print("      Temporal Analysis: Days Exceeding 70ppm Threshold")
    print("                  at point near Station 3")
    print("="*60)
    print(df.to_string())
    print("="*60 + "\n")


if __name__ == "__main__":
    main()
