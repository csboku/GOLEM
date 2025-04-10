#!/usr/bin/env python
"""
Example usage of the refactored GOLEM Python library functions.
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Import functions directly from the refactored module
# Assuming the refactored code is saved as 'golem_refactored.py'
import golem_refactored as golem

# Example 1: Data Processing
print("Example 1: Data Processing")

# Create mock data
np.random.seed(123)
data = np.random.normal(100, 20, 100)
data[np.random.choice(100, 10, replace=False)] = np.nan # Add some NaNs

# Remove missing values using the module function
clean_data = golem.remove_missing(data)
print(f"Original data length: {len(data)}, Clean data length: {len(clean_data)}")

# Calculate exceedances using the module function
exceedances = golem.calculate_exceedances(clean_data, threshold=120)
exceed_count = np.sum(exceedances)
print(f"Number of exceedances (>120): {exceed_count} out of {len(clean_data)}")

# --- Filter by season ---
# Create example DataFrame with dates
dates_index = pd.date_range(start='2021-01-01', end='2021-12-31', freq='D')
values = np.random.normal(100, 15, len(dates_index))
# Add a simple seasonal cycle for demonstration
values += np.sin(np.linspace(0, 4*np.pi, len(dates_index))) * 20
df = pd.DataFrame({'date': dates_index, 'value': values, 'altitude': np.random.uniform(500, 2000, len(dates_index))})

# Filter for summer months (JJA) using the module function
summer_data = golem.filter_by_season(df, date_col='date', season='JJA')
print(f"Original data points: {len(df)}")
print(f"Summer (JJA) data points: {len(summer_data)}")

# Filter by altitude using the module function
low_altitude_data = golem.filter_by_altitude(df, alt_col='altitude', max_alt=1000)
print(f"Low altitude (<1000m) data points: {len(low_altitude_data)}")


# Example 2: Visualization
print("\nExample 2: Visualization")

# Set up a multi-panel figure using the module function
fig, axes = golem.setup_multi_panel(
    nrows=2,
    ncols=2,
    figsize=(14, 10),
    height_ratios=[1, 0.7] # Example: Make top row taller
)

# --- Create boxplot data ---
# Mock data representing different scenarios and seasons
labels = ['Allyear', 'MAM', 'JJA'] # Categories
positions = np.arange(len(labels)) # X-axis positions for categories
# Define some distinct colors
colors = ['#1f77b4', '#ff7f0e', '#2ca02c', '#d62728', '#9467bd']

# Data: Dict[Scenario -> List[Data for each category]]
box_data = {
    'Historic': [list(np.random.normal(80, 20, 50)) for _ in labels],
    'RCP4.5 NF': [list(np.random.normal(75, 15, 50)) for _ in labels],
    'RCP8.5 NF': [list(np.random.normal(85, 25, 50)) for _ in labels],
    'RCP4.5 FF': [list(np.random.normal(70, 10, 50)) for _ in labels],
    'RCP8.5 FF': [list(np.random.normal(90, 30, 50)) for _ in labels]
}

# Create boxplots using the module function
golem.create_boxplot_comparison(
    ax=axes[0], # Target the first subplot
    data_dict=box_data,
    labels=labels,
    positions=positions,
    colors=colors,
    title='WRFChem Simulation',
    ylabel='MDA8 O₃ [μg/m³]'
)

# Create a similar plot for another model (e.g., CAMx) on the second subplot
# (Using slightly modified data for variation)
box_data_camx = {k: [list(np.array(d) * np.random.uniform(0.95, 1.05)) for d in v] for k, v in box_data.items()}
golem.create_boxplot_comparison(
    ax=axes[1], # Target the second subplot
    data_dict=box_data_camx,
    labels=labels,
    positions=positions,
    colors=colors,
    title='CAMx Simulation',
    ylabel='MDA8 O₃ [μg/m³]'
)

# --- Create bar chart data ---
periods = ['Allyear', 'MAM', 'JJA', 'SON']
# Mock exceedance counts for different scenarios and periods
exceedance_data = {
    'Historic': [75, 28, 42, 3],
    'RCP4.5 NF': [70, 30, 32, 2],
    'RCP8.5 NF': [90, 35, 40, 4],
    'RCP4.5 FF': [20, 15, 12, 2],
    'RCP8.5 FF': [90, 38, 42, 5]
}

# Create bar charts using the module function
golem.create_bar_comparison(
    ax=axes[2], # Target the third subplot
    data_dict=exceedance_data,
    labels=periods,
    colors=colors,
    title='WRFChem Exceedances (Count)',
    ylabel='Exceedances'
)

# Slightly modify data for the second bar chart
exceedance_data_camx = {
    k: [max(0, int(v * np.random.uniform(0.9, 1.1))) for v in vals] # Ensure non-negative counts
    for k, vals in exceedance_data.items()
}
golem.create_bar_comparison(
    ax=axes[3], # Target the fourth subplot
    data_dict=exceedance_data_camx,
    labels=periods,
    colors=colors,
    title='CAMx Exceedances (Count)',
    ylabel='Exceedances'
)

# Add a shared legend to the figure
handles = [plt.Rectangle((0,0),1,1, color=color) for color in colors[:len(exceedance_data)]]
fig.legend(handles, list(exceedance_data.keys()),
           loc='lower center', # Place legend at the bottom center
           bbox_to_anchor=(0.5, 0.01), # Adjust position slightly below axes
           ncol=len(exceedance_data), # Arrange horizontally
           title="Scenarios",
           fontsize='small')

plt.tight_layout(rect=[0, 0.05, 1, 1]) # Adjust layout to prevent overlap with legend (leave space at bottom)
# plt.subplots_adjust(bottom=0.15) # Alternative way to adjust space

# Example 3: Statistics
print("\nExample 3: Statistics")

# Create mock data for observations and model
np.random.seed(456)
obs = np.random.normal(100, 15, 100)
# Add some NaNs to observations
obs[np.random.choice(100, 5, replace=False)] = np.nan
model = obs + np.random.normal(5, 10, 100) # Model = obs + bias + noise
# Add some different NaNs to model
model[np.random.choice(100, 8, replace=False)] = np.nan

# Calculate statistics using the module function
metrics = golem.calc_statistical_metrics(obs, model)
print("Statistical metrics (Obs vs Model):")
for key, value in metrics.items():
    # Format floats nicely
    print(f"  {key}: {value:.4f}" if isinstance(value, float) else f"  {key}: {value}")

# Compare multiple models using the module function
model_dict = {
    'Model A': obs + np.random.normal(5, 10, 100),
    'Model B': obs + np.random.normal(0, 15, 100),
    'Model C': obs * 1.1 + np.random.normal(-3, 8, 100) # Introduce multiplicative bias
}
# Add some NaNs to the models for realism
model_dict['Model A'][0:10] = np.nan
model_dict['Model C'][-5:] = np.nan


comparison_df = golem.compare_models(obs, model_dict)
print("\nModel comparison:")
# Display the resulting DataFrame
# Format float columns for better readability
float_cols = ['bias', 'rmse', 'mae', 'correlation']
format_dict = {col: '{:.4f}'.format for col in float_cols}
print(comparison_df.to_string(index=False, formatters=format_dict))


# Calculate exceedance stats
all_data = {'Observations': obs, **model_dict} # Combine obs and models
exceed_stats = golem.calc_exceedance_stats(all_data, threshold=110)
print("\nExceedance counts (>110):")
print(exceed_stats)

# Calculate exceedance stats by season
# Need a date index corresponding to the data
stat_dates = pd.to_datetime(np.arange(len(obs)), unit='D', origin='2020-01-01')
try:
    exceed_stats_seasonal = golem.calc_exceedance_stats(all_data, threshold=110, by_season=True, dates=stat_dates)
    print("\nSeasonal Exceedance counts (>110):")
    # Print seasonal stats nicely
    for model_name, seasonal_data in exceed_stats_seasonal.items():
        print(f"  {model_name}: {seasonal_data}")
except ValueError as e:
    print(f"\nError calculating seasonal stats: {e}")


# Example 4: Spatial operations
print("\nExample 4: Spatial operations")

# Create mock raster data and coordinates
lons = np.linspace(10, 20, 20) # 20 longitude points
lats = np.linspace(45, 55, 25) # 25 latitude points (monotonically increasing)
# Raster data shape should be (n_lats, n_lons)
raster1 = np.random.rand(25, 20) * 50 + 75 # Values between 75 and 125
raster2 = raster1 * np.random.uniform(0.9, 1.1, size=(25, 20)) # Second raster similar to first

# Define points to extract (lon, lat)
points = [(12.5, 48.2), (15.1, 50.5), (18.9, 54.8), (9.0, 46.0)] # Include one point potentially outside

# Extract points using the module function
extracted_values = golem.extract_points(raster1, lons, lats, points, method='nearest')
print("\nExtracted values from raster1:")
for (lon, lat), value in zip(points, extracted_values):
    print(f"  Point ({lon:.1f}, {lat:.1f}): {value:.2f}") # Format output

# Calculate raster difference using the module function
diff_raster = golem.raster_difference(raster1, raster2)
print(f"\nRaster difference (raster1 - raster2) stats:")
print(f"  Min: {np.nanmin(diff_raster):.2f}")
print(f"  Max: {np.nanmax(diff_raster):.2f}")
print(f"  Mean: {np.nanmean(diff_raster):.2f}")


print("\nGOLEM Python refactored examples completed.")

# Display the plot created in Example 2
plt.show()

# To save the figure, uncomment the line below:
# golem.save_figure(fig, 'air_quality_comparison_refactored', formats=['png', 'pdf'])
