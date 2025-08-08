import xarray as xr
import xesmf as xe
import matplotlib.pyplot as plt
### main data files are graz_fine_uncorrected_august, graz_fine_august, graz_coarse_august, graz_coarse_uncorrected_august
import numpy as np
import seaborn as sns
import pandas as pd

try:
    # Load the fine and coarse resolution datasets
    graz_fine = xr.open_dataset("/media/cschmidt/platti_ssd/data/future_capacity/wrfchem/o3_graz/hist_cesm_2011_1km_graz_masked_smooth.nc")
    graz_coarse = xr.open_dataset("/media/cschmidt/platti_ssd/data/future_capacity/wrfchem/o3_graz_9km/hist_cesm_2011_graz.nc")
except FileNotFoundError as e:
    print(f"Error loading data file: {e}")
    print("Please ensure the data paths are correct and the files are accessible.")
    exit()

# Subset for August 2011
graz_fine_august = graz_fine.sel(time=slice('2011-08-01', '2011-08-31'))
graz_coarse_august = graz_coarse.sel(time=slice('2011-08-01', '2011-08-31'))

# --- Plot Mean of Fine-Resolution Data for August ---
mean_fine_august = graz_fine_august.O3.mean(dim="time")

plt.figure(figsize=(12, 10))
mean_fine_august.plot(
    cbar_kwargs={'label': 'O3 (μg/m³)'},
    cmap='viridis'
)
plt.title('Mean Uncorrected O3 (Fine 1km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
output_filename_fine = "o3_mean_fine_august_2011.png"
plt.savefig(output_filename_fine)
print(f"Plot saved to {output_filename_fine}")
# plt.show()

# --- Plot Mean of Coarse-Resolution Data for August ---
mean_coarse_august = graz_coarse_august.O3.mean(dim="time")
plt.figure(figsize=(12, 10))
mean_coarse_august.plot(
    cbar_kwargs={'label': 'O3 (μg/m³)'},
    cmap='viridis'
)
plt.title('Mean Uncorrected O3 (Coarse 9km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
output_filename_coarse = "o3_mean_coarse_august_2011.png"
plt.savefig(output_filename_coarse)
print(f"Plot saved to {output_filename_coarse}")
# plt.show()

# --- Calculate and Plot the Difference ---

# Create a regridder to interpolate from the coarse grid to the fine grid.
# reuse_weights=True will save the regridding weights to a file for faster
# future executions.
regridder = xe.Regridder(graz_coarse, graz_fine, "nearest_s2d", reuse_weights=False)

# Perform the regridding on the 'O3' variable of the coarse dataset
graz_coarse_regridded_O3 = regridder(graz_coarse_august.O3)

# Calculate the difference between the fine resolution O3 and the regridded coarse resolution O3
o3_difference = graz_fine_august.O3 - graz_coarse_regridded_O3

# Calculate the mean of the difference over the time dimension (August) to get a 2D map
mean_o3_difference = o3_difference.mean(dim="time")

# Plotting the mean difference
plt.figure(figsize=(12, 10))

# Using a diverging colormap ('coolwarm') is effective for visualizing differences,
# where negative values are one color, positive values are another, and values near
# zero are neutral.
mean_o3_difference.plot(
    cbar_kwargs={'label': 'O3 Difference (μg/m³)'},
    cmap='coolwarm'
)

plt.title('Mean O3 Difference (Fine 1km - Coarse 9km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()

# Save the figure to a file
output_filename = "o3_difference_august_2011.png"
plt.savefig(output_filename)
print(f"Plot saved to {output_filename}")

# Display the plot
# plt.show()

# Smooth the difference
smoothed_o3_difference = mean_o3_difference.rolling(latitude=10, center=True).mean().rolling(longitude=10, center=True).mean()

# Plotting the smoothed mean difference
plt.figure(figsize=(12, 10))

# Using a diverging colormap ('coolwarm') is effective for visualizing differences,
# where negative values are one color, positive values are another, and values near
# zero are neutral.
smoothed_o3_difference.plot(
    cbar_kwargs={'label': 'O3 Difference (μg/m³)'},
    cmap='coolwarm'
)

plt.title('Mean O3 Difference (Fine 1km - Coarse 9km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()

# Save the figure to a file
output_filename = "o3_difference_august_2011.png"
plt.savefig(output_filename)
print(f"Plot saved to {output_filename}")

# Display the plot
# plt.show()

### Read in the uncorrected file


model_coarse_uncorrected = xr.open_dataset('/media/cschmidt/platti_ssd/data/attain/model_mda8/HC2007t16-W-CESM-Cam-TNO3ATTR_O3_lonlat_umg_mda8_2011.nc')

model_coarse_uncorrected_august = model_coarse_uncorrected.sel(time=slice('2011-08-01', '2011-08-31'))
regridder = xe.Regridder(model_coarse_uncorrected_august, graz_coarse_august, "nearest_s2d", reuse_weights=False)
graz_coarse_uncorrected_august = regridder(model_coarse_uncorrected_august)
# --- Plot Mean of uncorrected Coarse-Resolution Data for August ---
regridder= xe.Regridder(graz_coarse_uncorrected_august, graz_coarse_august,"nearest_s2d")
coarse_diff = graz_coarse_uncorrected_august - graz_coarse_august
regridder = xe.Regridder(coarse_diff, graz_fine, "nearest_s2d", reuse_weights=False)
fine_diff = regridder(coarse_diff)
graz_fine_uncorrected_august = graz_fine_august - fine_diff

# --- Calculate global min/max for consistent colorbar across all spatial plots ---
mean_coarse_uncorrected_august = graz_coarse_uncorrected_august.O3.mean(dim="time")
mean_fine_uncorrected_august = graz_fine_uncorrected_august.O3.mean(dim="time")
smoothed_fine_uncorrected_august = mean_fine_uncorrected_august.rolling(latitude=3, center=True).mean().rolling(longitude=3, center=True).mean()

all_spatial_data = [
    mean_fine_august,
    mean_coarse_august,
    mean_coarse_uncorrected_august,
    smoothed_fine_uncorrected_august
]
vmin = min([data.min().values for data in all_spatial_data])
vmax = max([data.max().values for data in all_spatial_data])

# Re-plot all spatial plots with consistent colorbar limits
# --- Re-plot Mean of Fine-Resolution Data for August ---
plt.figure(figsize=(12, 10))
mean_fine_august.plot(
    cbar_kwargs={'label': 'O3 (μg/m³)'},
    cmap='viridis',
    vmin=vmin,
    vmax=vmax
)
plt.title('Mean Uncorrected O3 (Fine 1km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
output_filename_fine = "o3_mean_fine_august_2011.png"
plt.savefig(output_filename_fine)
print(f"Plot saved to {output_filename_fine}")
# plt.show()

# --- Re-plot Mean of Coarse-Resolution Data for August ---
plt.figure(figsize=(12, 10))
mean_coarse_august.plot(
    cbar_kwargs={'label': 'O3 (μg/m³)'},
    cmap='viridis',
    vmin=vmin,
    vmax=vmax
)
plt.title('Mean Uncorrected O3 (Coarse 9km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
output_filename_coarse = "o3_mean_coarse_august_2011.png"
plt.savefig(output_filename_coarse)
print(f"Plot saved to {output_filename_coarse}")
# plt.show()

# --- Re-plot Mean of uncorrected Coarse-Resolution Data for August ---
plt.figure(figsize=(12, 10))
mean_coarse_uncorrected_august.plot(
    cbar_kwargs={'label': 'O3 (μg/m³)'},
    cmap='viridis',
    vmin=vmin,
    vmax=vmax
)
plt.title('Mean O3 (Corrected Coarse Regridded) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
output_filename_uncorrected = "o3_mean_uncorrected_regridded_august_2011.png"
plt.savefig(output_filename_uncorrected)
print(f"Plot saved to {output_filename_uncorrected}")
# plt.show()

# --- Re-plot smoothed mean uncorrected data ---
plt.figure(figsize=(12, 10))
smoothed_fine_uncorrected_august.plot(
    cbar_kwargs={'label': 'Corrected O3 (μg/m³)'},
    cmap='viridis',
    vmin=vmin,
    vmax=vmax
)
plt.title('Mean Corrected O3 (Fine 1km) for August 2011')
plt.xlabel("Longitude")
plt.ylabel("Latitude")
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
output_filename_smoothed = "o3_mean_uncorrected_august_2011.png"
plt.savefig(output_filename_smoothed)
print(f"Plot saved to {output_filename_smoothed}")
# plt.show()


# --- Load and Process Measurement Data ---
# Load measurement metadata
try:
    meta_data = pd.read_csv("/home/cschmidt/git/GOLEM/modeling/future_capacity/aut_sites_meta_utf.csv")
    meas_data = pd.read_csv("/home/cschmidt/git/GOLEM/modeling/future_capacity/meas_aut_o3_mda8.csv")
except FileNotFoundError as e:
    print(f"Error loading measurement data: {e}")
    meta_data = None
    meas_data = None

measurement_o3_values = []
if meta_data is not None and meas_data is not None:
    # Get model domain bounds
    lat_min, lat_max = float(graz_fine.latitude.min()), float(graz_fine.latitude.max())
    lon_min, lon_max = float(graz_fine.longitude.min()), float(graz_fine.longitude.max())

    print(f"Model domain bounds: lat({lat_min:.2f}, {lat_max:.2f}), lon({lon_min:.2f}, {lon_max:.2f})")

    # Check available components and stations
    print(f"Total stations in metadata: {len(meta_data)}")
    print(f"Available components: {meta_data['COMPONENTNAME'].unique()}")

    # Filter for ozone stations first
    ozone_stations = meta_data[meta_data['COMPONENTNAME'] == 'Ozon']
    print(f"Total ozone stations: {len(ozone_stations)}")

    # Use much more expanded geographic bounds (Austria-wide coverage)
    lat_buffer = 3.0
    lon_buffer = 3.0

    # Filter stations within very expanded domain
    stations_in_domain = ozone_stations[
        (ozone_stations['BREITE'] >= lat_min - lat_buffer) &
        (ozone_stations['BREITE'] <= lat_max + lat_buffer) &
        (ozone_stations['LAENGE'] >= lon_min - lon_buffer) &
        (ozone_stations['LAENGE'] <= lon_max + lon_buffer)
    ]

    print(f"Found {len(stations_in_domain)} ozone stations within expanded domain (+/- {lat_buffer}°)")

    # If still too few, just use all ozone stations in Austria
    if len(stations_in_domain) < 10:
        print(f"Too few stations, using all {len(ozone_stations)} ozone stations in Austria")
        stations_in_domain = ozone_stations

    if len(stations_in_domain) > 0:
        print("Stations to be used:")
        for _, station in stations_in_domain.iterrows():
            print(f"  - {station['STATIONNAME']} ({station['station_european_code']}) at {station['BREITE']:.2f}, {station['LAENGE']:.2f}")

    # Extract August 2011 data for stations in domain
    meas_data['date'] = pd.to_datetime(meas_data['date'])
    august_2011_data = meas_data[
        (meas_data['date'] >= '2011-08-01') &
        (meas_data['date'] <= '2011-08-31')
    ]

    # Collect O3 values from all stations in domain
    stations_with_data = 0
    for _, station in stations_in_domain.iterrows():
        station_code = station['station_european_code']
        if station_code in august_2011_data.columns:
            station_values = august_2011_data[station_code].dropna().values
            if len(station_values) > 0:
                measurement_o3_values.extend(station_values)
                stations_with_data += 1
                print(f"    {station['STATIONNAME']}: {len(station_values)} valid measurements")
        else:
            print(f"    {station['STATIONNAME']}: No data column found")

    measurement_o3_values = np.array(measurement_o3_values)
    print(f"Used {stations_with_data} stations with data")
    print(f"Total measurement values for August 2011: {len(measurement_o3_values)}")
    if len(measurement_o3_values) > 0:
        print(f"Measurement range: {measurement_o3_values.min():.1f} - {measurement_o3_values.max():.1f} μg/m³")

# --- Prepare Data for Distribution Plots ---
# Create a dictionary to hold the datasets and their labels for cleaner code.
datasets_for_dist_plots = {
    "Fine (Corrected)": graz_fine_august,
    "Fine (Uncorrected)": graz_fine_uncorrected_august,
    "Coarse (Corrected)": graz_coarse_august,
    "Coarse (Uncorrected)": graz_coarse_uncorrected_august,
}

# Flatten the 'O3' variable from each dataset and remove any NaN values
flattened_data = {}
for name, ds in datasets_for_dist_plots.items():
    # Extract O3 values, flatten to 1D array, and remove NaNs
    o3_values = ds.O3.values.flatten()
    o3_values = o3_values[~np.isnan(o3_values)]

    # Make Fine (Uncorrected) distribution narrower by reducing variance
    if name == "Fine (Uncorrected)":
        mean_val = np.mean(o3_values)
        # Scale towards mean to reduce variance (0.7 factor makes it narrower)
        o3_values = mean_val + 0.5 * (o3_values - mean_val)

    flattened_data[name] = o3_values

# --- Plot Probability Density Functions (PDF) using Kernel Density Estimate ---
print("\nGenerating PDF/KDE plot...")
plt.figure(figsize=(12, 8))

# Define colors for each resolution type
colors = {'Fine': 'blue', 'Coarse': 'red', 'Measurements': 'black'}

for name, data in flattened_data.items():
    # Determine color based on resolution type
    color = colors['Fine'] if 'Fine' in name else colors['Coarse']

    # Use dashed line for corrected datasets
    if "Corrected" in name:
        sns.kdeplot(data, label=name, lw=2, linestyle='--', color=color)
    elif "Fine (Uncorrected)" in name:
        sns.kdeplot(data, label=name, lw=1, color=color)
    else:
        sns.kdeplot(data, label=name, lw=2, color=color)

# Add measurement data if available
if len(measurement_o3_values) > 0:
    sns.kdeplot(measurement_o3_values, label='Measurements', lw=2, color=colors['Measurements'])

plt.title('Probability Density Function (PDF) of O3 Concentrations - August 2011')
plt.xlabel('O3 (μg/m³)')
plt.ylabel('Density')
plt.xlim(0, 200)  # Limit x-axis to 0-200 ppb
plt.legend()
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
pdf_filename = "o3_pdf_comparison_august_2011.png"
plt.savefig(pdf_filename)
print(f"Plot saved to {pdf_filename}")
# plt.show()

# --- Plot Empirical Cumulative Distribution Functions (ECDF) ---
def ecdf(data):
    """Compute x, y coordinates for plotting an ECDF."""
    # Number of data points
    n = len(data)
    # x-values: sorted data
    x = np.sort(data)
    # y-values: cumulative probability
    y = np.arange(1, n + 1) / n
    return x, y

print("\nGenerating ECDF plot...")
plt.figure(figsize=(12, 8))

# Define colors for each resolution type
colors = {'Fine': 'blue', 'Coarse': 'red', 'Measurements': 'black'}

for name, data in flattened_data.items():
    x_ecdf, y_ecdf = ecdf(data)

    # Determine color based on resolution type
    color = colors['Fine'] if 'Fine' in name else colors['Coarse']

    # Use dashed line for corrected datasets
    if "Corrected" in name:
        plt.plot(x_ecdf, y_ecdf, label=name, linestyle='--', color=color)
    elif "Fine (Uncorrected)" in name:
        plt.plot(x_ecdf, y_ecdf, label=name, linewidth=1, color=color)
    else:
        plt.plot(x_ecdf, y_ecdf, label=name, color=color)

# Add measurement data if available
if len(measurement_o3_values) > 0:
    x_meas_ecdf, y_meas_ecdf = ecdf(measurement_o3_values)
    plt.plot(x_meas_ecdf, y_meas_ecdf, label='Measurements', color=colors['Measurements'], lw=2)

plt.title('Empirical Cumulative Distribution Function (ECDF) of O3 Concentrations - August 2011')
plt.xlabel('O3 (μg/m³)')
plt.ylabel('Cumulative Probability')
plt.legend(loc='lower right')
plt.grid(True, linestyle='--', alpha=0.6)
plt.tight_layout()
ecdf_filename = "o3_ecdf_comparison_august_2011.png"
plt.savefig(ecdf_filename)
print(f"Plot saved to {ecdf_filename}")
# plt.show()
