"""
Visualizes the results of the bias correction experiment.
"""

import xarray as xr
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
import config

def plot_histograms(original_data, corrected_data, station_data, title, filename):
    """Plots a comparison of the histograms for a given dataset."""
    plt.figure(figsize=(18, 9))
    
    original_data.plot.hist(bins=50, alpha=0.8, label="Original Model", histtype="step", linewidth=2.5, density=True)
    station_data.stack(all_obs=("station", "time")).plot.hist(bins=50, alpha=0.5, label="Stations (Observed)", histtype="stepfilled", density=True)

    for name, data in corrected_data.items():
        data.plot.hist(bins=50, alpha=0.8, label=name.replace("_", " ").title(), histtype="step", linewidth=1.5, density=True)
        
    plt.axvline(config.THRESHOLD_VALUE, color="black", linestyle="--", linewidth=2, label=f"Threshold ({config.THRESHOLD_VALUE} {config.VARIABLE_UNIT})")
    plt.legend(loc='upper right')
    plt.title(title)
    plt.xlabel(f"{config.VARIABLE_NAME} ({config.VARIABLE_UNIT})")
    plt.ylabel("Probability Density")
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.savefig(filename)
    plt.close()

def plot_pdfs(original_data, corrected_data, station_data, title, filename):
    """Plots a comparison of the Probability Density Functions (PDFs)."""
    plt.figure(figsize=(18, 9))
    sns.set_theme(style="whitegrid")
    
    sns.kdeplot(data=original_data.values.flatten(), label="Original Model", linewidth=2.5)
    sns.kdeplot(data=station_data.stack(all_obs=("station", "time")).values, label="Stations (Observed)", linewidth=2.5, linestyle='--')

    for name, data in corrected_data.items():
        sns.kdeplot(data=data.values.flatten(), label=name.replace("_", " ").title(), linewidth=1.5)
        
    plt.axvline(config.THRESHOLD_VALUE, color="black", linestyle=":", linewidth=2, label=f"Threshold ({config.THRESHOLD_VALUE} {config.VARIABLE_UNIT})")
    plt.legend()
    plt.title(title)
    plt.xlabel(f"{config.VARIABLE_NAME} ({config.VARIABLE_UNIT})")
    plt.ylabel("Probability Density")
    plt.savefig(filename)
    plt.close()

def plot_ecdfs(original_data, corrected_data, station_data, title, filename):
    """Plots a comparison of the Empirical Cumulative Distribution Functions (ECDFs)."""
    plt.figure(figsize=(18, 9))
    sns.set_theme(style="whitegrid")

    sns.ecdfplot(data=original_data.values.flatten(), label="Original Model", linewidth=2.5)
    sns.ecdfplot(data=station_data.stack(all_obs=("station", "time")).values, label="Stations (Observed)", linewidth=2.5, linestyle='--')

    for name, data in corrected_data.items():
        sns.ecdfplot(data=data.values.flatten(), label=name.replace("_", " ").title(), linewidth=1.5)

    plt.axvline(config.THRESHOLD_VALUE, color="black", linestyle=":", linewidth=2, label=f"Threshold ({config.THRESHOLD_VALUE} {config.VARIABLE_UNIT})")
    plt.legend(loc='center right')
    plt.title(title)
    plt.xlabel(f"{config.VARIABLE_NAME} ({config.VARIABLE_UNIT})")
    plt.ylabel("Cumulative Probability")
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.savefig(filename)
    plt.close()

def plot_spatial(original_data, corrected_data, title_prefix, filename):
    """Plots a spatial comparison for a given dataset."""
    methods = list(corrected_data.keys())
    n_plots = len(methods) + 1
    fig, axes = plt.subplots(1, n_plots, figsize=(n_plots * 4, 4))
    
    original_data.plot(ax=axes[0], cmap="viridis", cbar_kwargs={'label': ''})
    axes[0].set_title("Original")
    
    for i, (name, data) in enumerate(corrected_data.items()):
        data.plot(ax=axes[i+1], cmap="viridis", cbar_kwargs={'label': ''})
        axes[i+1].set_title(name.replace("_", " ").title())
        
    fig.suptitle(title_prefix, fontsize=16)
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.savefig(filename)
    plt.close()

def main():
    """Main function to visualize the results."""
    station_data = xr.open_dataset("station_data.nc")[config.VARIABLE_NAME]

    corrected_methods = [
        "scaling", "delta", "variance", "parametric", "parametric_gamma", "qm", "spatial_delta"
    ]

    for scenario in ["1km", "9km"]:
        original_data = xr.open_dataset(f"ds_{scenario}.nc")[config.VARIABLE_NAME]
        corrected_data = {
            name: xr.open_dataset(f"corrected_ds_{scenario}_{name}.nc")[config.VARIABLE_NAME]
            for name in corrected_methods
        }
        
        plot_histograms(original_data, corrected_data, station_data, f"{scenario.upper()} Histogram Comparison", f"histogram_comparison_{scenario}.png")
        plot_spatial(original_data, corrected_data, f"{scenario.upper()} Spatial Comparison", f"spatial_comparison_{scenario}.png")
        plot_pdfs(original_data, corrected_data, station_data, f"{scenario.upper()} PDF Comparison", f"pdf_comparison_{scenario}.png")
        plot_ecdfs(original_data, corrected_data, station_data, f"{scenario.upper()} ECDF Comparison", f"ecdf_comparison_{scenario}.png")

if __name__ == "__main__":
    main()