"""
Generates all figures required for the detailed scientific report.
"""
import numpy as np
import xarray as xr
import matplotlib.pyplot as plt
from scipy.stats import norm, gaussian_kde
import config

def plot_qm_schematic():
    """Creates and saves the Quantile Mapping schematic figure."""
    model_dist = norm(loc=5, scale=1.5)
    obs_dist = norm(loc=8, scale=2.0)
    x = np.linspace(-2, 15, 500)
    model_value = 4.0
    percentile = model_dist.cdf(model_value)
    corrected_value = obs_dist.ppf(percentile)

    fig, ax = plt.subplots(figsize=(10, 6))
    ax.plot(x, model_dist.pdf(x), color='red', linewidth=2, label='Biased Model PDF')
    ax.plot(x, obs_dist.pdf(x), color='green', linewidth=2, label='Observed PDF (Truth)')
    ax.plot([model_value, model_value], [0, model_dist.pdf(model_value)], color='red', linestyle='--')
    ax.annotate("", xy=(corrected_value, obs_dist.pdf(corrected_value)), xytext=(model_value, model_dist.pdf(model_value)),
                arrowprops=dict(arrowstyle="->", color='black', lw=1.5, connectionstyle="arc3,rad=0.2"))
    ax.plot([corrected_value, corrected_value], [0, obs_dist.pdf(corrected_value)], color='green', linestyle='--')
    ax.text(model_value - 0.5, -0.015, f'{model_value:.1f}', color='red', ha='center')
    ax.text(corrected_value, -0.015, f'{corrected_value:.1f}', color='green', ha='center')
    ax.text((model_value + corrected_value) / 2, model_dist.pdf(model_value) * 1.1,
             f'CDF = {percentile:.2f}', ha='center', bbox=dict(facecolor='white', alpha=0.8, edgecolor='none'))
    ax.set_title('The Concept of Quantile Mapping', fontsize=16)
    ax.set_xlabel('Value (e.g., Pollutant X in ppm)')
    ax.set_ylabel('Probability Density')
    ax.legend()
    ax.set_ylim(bottom=0)
    plt.tight_layout()
    plt.savefig('qm_schematic.png', dpi=300)
    print("Successfully generated qm_schematic.png")

def plot_spatial_results():
    """Creates a multi-panel figure showing spatial results."""
    original = xr.open_dataset("ds_1km.nc")[config.VARIABLE_NAME]
    variance = xr.open_dataset("corrected_ds_1km_variance.nc")[config.VARIABLE_NAME]
    qm = xr.open_dataset("corrected_ds_1km_qm.nc")[config.VARIABLE_NAME]
    difference = variance - original

    fig, axes = plt.subplots(2, 2, figsize=(12, 10), sharex=True, sharey=True)
    fig.suptitle('Spatial Effects of Bias Correction (1km Bimodal Scenario)', fontsize=16)
    
    vmin = min(original.min(), variance.min(), qm.min())
    vmax = max(original.max(), variance.max(), qm.max())
    
    # Station locations
    station_x = [loc[0] for loc in config.STATION_LOCATIONS.values()]
    station_y = [loc[1] for loc in config.STATION_LOCATIONS.values()]

    # Plot Original
    original.plot(ax=axes[0, 0], cmap='viridis', vmin=vmin, vmax=vmax, add_colorbar=False)
    axes[0, 0].scatter(station_x, station_y, marker='x', color='white', s=50, label='Stations')
    axes[0, 0].set_title('a) Original Biased Model')

    # Plot Variance Scaling
    variance.plot(ax=axes[0, 1], cmap='viridis', vmin=vmin, vmax=vmax, add_colorbar=False)
    axes[0, 1].scatter(station_x, station_y, marker='x', color='white', s=50)
    axes[0, 1].set_title('b) Corrected (Variance Scaling)')

    # Plot Quantile Mapping
    qm.plot(ax=axes[1, 0], cmap='viridis', vmin=vmin, vmax=vmax, add_colorbar=False)
    axes[1, 0].scatter(station_x, station_y, marker='x', color='white', s=50)
    axes[1, 0].set_title('c) Corrected (Quantile Mapping)')

    # Plot Difference
    diff_max = abs(difference).max()
    difference.plot(ax=axes[1, 1], cmap='RdBu', vmin=-diff_max, vmax=diff_max, add_colorbar=False)
    axes[1, 1].scatter(station_x, station_y, marker='x', color='black', s=50)
    axes[1, 1].set_title('d) Difference (Variance Scaling - Original)')

    fig.colorbar(axes[0,0].collections[0], ax=axes[0:2, 0:2], orientation='vertical', label='Pollutant X (ppm)', fraction=0.08)
    fig.colorbar(axes[1,1].collections[0], ax=axes[1, 1], orientation='vertical', label='Difference (ppm)', fraction=0.08)

    plt.tight_layout(rect=[0, 0, 1, 0.96])
    plt.savefig('spatial_comparison_report.png', dpi=300)
    print("Successfully generated spatial_comparison_report.png")

def plot_distribution_results():
    """Creates a figure comparing the PDFs of key methods."""
    original = xr.open_dataset("ds_1km.nc")[config.VARIABLE_NAME].values.flatten()
    stations = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME].stack(all_obs=("station", "time")).values
    variance = xr.open_dataset("corrected_ds_1km_variance.nc")[config.VARIABLE_NAME].values.flatten()
    qm = xr.open_dataset("corrected_ds_1km_qm.nc")[config.VARIABLE_NAME].values.flatten()

    fig, ax = plt.subplots(figsize=(10, 6))
    
    x_range = np.linspace(30, 90, 500)
    
    # Calculate KDEs
    kde_orig = gaussian_kde(original)(x_range)
    kde_stat = gaussian_kde(stations)(x_range)
    kde_var = gaussian_kde(variance)(x_range)
    kde_qm = gaussian_kde(qm)(x_range)

    ax.plot(x_range, kde_orig, color='red', lw=2, label='Original Model')
    ax.plot(x_range, kde_stat, color='black', lw=2, linestyle='--', label='Stations (Observed)')
    ax.plot(x_range, kde_var, color='blue', lw=2, label='Corrected (Variance Scaling)')
    ax.plot(x_range, kde_qm, color='purple', lw=2, label='Corrected (Quantile Mapping)')
    
    ax.axvline(config.THRESHOLD_VALUE, color='grey', linestyle=':', label=f'Threshold ({config.THRESHOLD_VALUE} ppm)')
    
    ax.set_title('Effect of Correction on the 1km Bimodal Distribution', fontsize=16)
    ax.set_xlabel('Pollutant X (ppm)')
    ax.set_ylabel('Probability Density')
    ax.legend()
    ax.set_ylim(bottom=0)
    ax.set_xlim(30, 90)
    
    plt.tight_layout()
    plt.savefig('distribution_comparison_report.png', dpi=300)
    print("Successfully generated distribution_comparison_report.png")

if __name__ == "__main__":
    plot_qm_schematic()
    plot_spatial_results()
    plot_distribution_results()
