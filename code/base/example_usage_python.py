#!/usr/bin/env python
"""
Example usage of GOLEM Python library.
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from GOLEM_python import DataProcessing, Visualization, Statistics, Spatial

# Example 1: Data Processing
print("Example 1: Data Processing")

# Create mock data
np.random.seed(123)
data = np.random.normal(100, 20, 100)
data[np.random.choice(100, 10, replace=False)] = np.nan

# Remove missing values
clean_data = DataProcessing.remove_missing(data)
print(f"Original data length: {len(data)}, Clean data length: {len(clean_data)}")

# Calculate exceedances
exceedances = DataProcessing.calculate_exceedances(clean_data, threshold=120)
exceed_count = np.sum(exceedances)
print(f"Number of exceedances: {exceed_count} out of {len(clean_data)}")

# Filter by season
# Create example DataFrame with dates
dates = pd.date_range(start='2021-01-01', end='2021-12-31', freq='D')
values = np.random.normal(100, 15, len(dates))
values += np.sin(np.linspace(0, 2*np.pi, len(dates))) * 20  # Add seasonal cycle
df = pd.DataFrame({'date': dates, 'value': values})

# Filter for summer months
summer_data = DataProcessing.filter_by_season(df, date_col='date', season='JJA')
print(f"Summer data points: {len(summer_data)} out of {len(df)}")

# Example 2: Visualization
print("\nExample 2: Visualization")

# Set up a multi-panel figure
fig, axes = Visualization.setup_multi_panel(
    nrows=2, 
    ncols=2, 
    figsize=(14, 10), 
    height_ratios=[1, 0.7]
)

# Create boxplot data
labels = ['Allyear', 'MAM', 'JJA']
positions = np.arange(len(labels))
colors = ['#006D77', '#FFB84C', '#F24C3D', '#8B4513', '#642C0C']

box_data = {
    'Historic': [np.random.normal(80, 20, 5) for _ in range(3)],
    'RCP4.5 NF': [np.random.normal(75, 15, 5) for _ in range(3)],
    'RCP8.5 NF': [np.random.normal(85, 25, 5) for _ in range(3)],
    'RCP4.5 FF': [np.random.normal(70, 10, 5) for _ in range(3)],
    'RCP8.5 FF': [np.random.normal(90, 30, 5) for _ in range(3)]
}

# Create boxplots
Visualization.create_boxplot_comparison(
    axes[0],
    box_data,
    labels,
    positions,
    colors[:len(box_data)],
    title='WRFChem',
    ylabel='MDA8 O₃ [μg/m³]'
)

Visualization.create_boxplot_comparison(
    axes[1],
    box_data,
    labels,
    positions,
    colors[:len(box_data)],
    title='CAMx',
    ylabel='MDA8 O₃ [μg/m³]'
)

# Create bar chart data
periods = ['Allyear', 'MAM', 'JJA', 'SON']
exceedance_data = {
    'Historic': [75, 28, 42, 3],
    'RCP4.5 NF': [70, 30, 32, 2],
    'RCP8.5 NF': [90, 35, 40, 4],
    'RCP4.5 FF': [20, 15, 12, 2],
    'RCP8.5 FF': [90, 38, 42, 5]
}

# Create bar charts
Visualization.create_bar_comparison(
    axes[2],
    exceedance_data,
    periods,
    colors[:len(exceedance_data)],
    title='WRFChem Exceedances',
    ylabel='Exceedances'
)

# Slightly modify data for CAMx
camx_exceedance_data = {
    k: [v * (1 + np.random.uniform(-0.1, 0.1)) for v in vals]
    for k, vals in exceedance_data.items()
}

Visualization.create_bar_comparison(
    axes[3],
    camx_exceedance_data,
    periods,
    colors[:len(camx_exceedance_data)],
    title='CAMx Exceedances',
    ylabel='Exceedances'
)

# Add legend
handles = [plt.Rectangle((0,0),1,1, color=color) for color in colors[:len(exceedance_data)]]
fig.legend(handles, list(exceedance_data.keys()),
          loc='upper center', bbox_to_anchor=(0.5, 0.05), ncol=5)

plt.tight_layout()
plt.subplots_adjust(bottom=0.15)

# Example 3: Statistics
print("\nExample 3: Statistics")

# Create mock data for observations and model
obs = np.random.normal(100, 15, 100)
model = obs + np.random.normal(5, 10, 100)  # Model = obs + bias + noise

# Calculate statistics
metrics = Statistics.calc_statistical_metrics(obs, model)
print("Statistical metrics:")
for key, value in metrics.items():
    print(f"  {key}: {value:.4f}" if isinstance(value, float) else f"  {key}: {value}")

# Compare multiple models
model_dict = {
    'Model A': obs + np.random.normal(5, 10, 100),
    'Model B': obs + np.random.normal(0, 15, 100),
    'Model C': obs + np.random.normal(-3, 8, 100)
}

comparison = Statistics.compare_models(obs, model_dict)
print("\nModel comparison:")
print(comparison[['model', 'bias', 'rmse', 'correlation']])

# Example 4: Spatial operations
print("\nExample 4: Spatial operations")

# Create mock raster data
lons = np.linspace(10, 20, 20)
lats = np.linspace(45, 55, 20)
raster1 = np.random.normal(100, 15, (20, 20))
raster2 = np.random.normal(95, 20, (20, 20))

# Extract points
points = [(12, 48), (15, 50), (18, 52)]
extracted = Spatial.extract_points(raster1, lons, lats, points)
print("Extracted values:")
for (lon, lat), value in zip(points, extracted):
    print(f"  Point ({lon}, {lat}): {value:.2f}")

# Calculate raster difference
diff = Spatial.raster_difference(raster1, raster2)
print(f"Raster difference stats - Min: {np.min(diff):.2f}, Max: {np.max(diff):.2f}, Mean: {np.mean(diff):.2f}")

print("\nGOLEM Python examples completed")

# To save the figure, uncomment these lines:
# Visualization.save_figure(fig, 'air_quality_comparison', formats=['png', 'pdf'])