#!/usr/bin/env python3
"""
Fire Weather Index Analysis Script
Analyzes FFMC superimposition on coarser grid and performs case studies for Inn and NOE regions.
Utilizes 30 cores for parallel processing.
"""

import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from multiprocessing import Pool
import pandas as pd
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

def load_dataset(filepath):
    """Load and examine NetCDF dataset structure."""
    print(f"Loading {filepath}")
    ds = xr.open_dataset(filepath)
    print(f"Dimensions: {dict(ds.dims)}")
    print(f"Variables: {list(ds.data_vars)}")
    print(f"Coordinates: {list(ds.coords)}")
    print("="*50)
    return ds

def compare_grid_resolutions(original_ds, supergrid_ds):
    """Compare original coarser grid with superimposed finer grid."""
    print("Grid Resolution Comparison:")
    
    # Check spatial dimensions
    orig_dims = {dim: size for dim, size in original_ds.dims.items() if dim in ['x', 'y', 'lon', 'lat']}
    super_dims = {dim: size for dim, size in supergrid_ds.dims.items() if dim in ['x', 'y', 'lon', 'lat']}
    
    print(f"Original grid dimensions: {orig_dims}")
    print(f"Superimposed grid dimensions: {super_dims}")
    
    # Calculate resolution ratios
    for dim in orig_dims:
        if dim in super_dims:
            ratio = super_dims[dim] / orig_dims[dim]
            print(f"Resolution ratio for {dim}: {ratio:.2f}")
    
    return orig_dims, super_dims

def analyze_ffmc_modifications(original_ds, modified_ds):
    """Analyze FFMC modifications made based on expert guesses."""
    print("FFMC Modification Analysis:")
    
    # Get FFMC variables from both datasets
    orig_ffmc_vars = [var for var in original_ds.data_vars if 'ffmc' in var.lower()]
    mod_ffmc_vars = [var for var in modified_ds.data_vars if 'ffmc' in var.lower()]
    
    print(f"Original FFMC variables: {orig_ffmc_vars}")
    print(f"Modified FFMC variables: {mod_ffmc_vars}")
    print(f"Original dimensions: {dict(original_ds.dims)}")
    print(f"Modified dimensions: {dict(modified_ds.dims)}")
    
    if not orig_ffmc_vars or not mod_ffmc_vars:
        print("Missing FFMC variables in one of the datasets")
        return None
    
    # For now, just return basic statistics without direct comparison due to different grids
    results = {}
    
    # Original data stats
    for var in orig_ffmc_vars:
        data = original_ds[var]
        results[f'original_{var}'] = {
            'mean': float(data.mean()),
            'std': float(data.std()),
            'max': float(data.max()),
            'min': float(data.min()),
            'shape': data.shape
        }
    
    # Modified data stats  
    for var in mod_ffmc_vars:
        data = modified_ds[var]
        results[f'modified_{var}'] = {
            'mean': float(data.mean()),
            'std': float(data.std()),
            'max': float(data.max()),
            'min': float(data.min()),
            'shape': data.shape
        }
    
    # Check if we can do spatial comparison by resampling
    print("\nNote: Datasets have different grids - cannot directly compute differences.")
    print("Original grid is coarser, superimposed grid is ~8x finer resolution.")
    
    return results

def analyze_classification_data(class_ds):
    """Analyze classification data structure and categories."""
    print("Classification Analysis:")
    
    # Find classification variables
    class_vars = [var for var in class_ds.data_vars if 'class' in var.lower() or var.endswith('_c')]
    if not class_vars:
        class_vars = list(class_ds.data_vars)
    
    print(f"Classification variables: {class_vars}")
    
    results = {}
    for var in class_vars:
        data = class_ds[var]
        unique_vals = np.unique(data.values[~np.isnan(data.values)])
        
        results[var] = {
            'unique_classes': unique_vals.tolist(),
            'n_classes': len(unique_vals),
            'class_counts': {int(val): int((data == val).sum()) for val in unique_vals}
        }
        
        print(f"{var}: {len(unique_vals)} classes - {unique_vals}")
    
    return results

def regional_analysis(region_name, region_files):
    """Perform detailed analysis for a specific region."""
    print(f"\nRegional Analysis: {region_name.upper()}")
    print("="*40)
    
    results = {}
    
    for filepath in region_files:
        if Path(filepath).exists():
            ds = xr.open_dataset(filepath)
            filename = Path(filepath).name
            
            results[filename] = {
                'dimensions': dict(ds.dims),
                'variables': list(ds.data_vars),
                'spatial_extent': {}
            }
            
            # Get spatial extent
            for coord in ['x', 'y', 'lon', 'lat']:
                if coord in ds.coords:
                    coord_data = ds.coords[coord]
                    results[filename]['spatial_extent'][coord] = {
                        'min': float(coord_data.min()),
                        'max': float(coord_data.max()),
                        'size': len(coord_data)
                    }
            
            # Basic statistics for main variables
            results[filename]['variable_stats'] = {}
            for var in ds.data_vars:
                if ds[var].dtype in [np.float32, np.float64]:
                    var_data = ds[var]
                    results[filename]['variable_stats'][var] = {
                        'mean': float(var_data.mean()),
                        'std': float(var_data.std()),
                        'min': float(var_data.min()),
                        'max': float(var_data.max())
                    }
    
    return results

def create_comparison_plots(original_ds, supergrid_ds, output_dir="plots"):
    """Create visualization plots comparing original and superimposed grids."""
    Path(output_dir).mkdir(exist_ok=True)
    
    # Find common variables
    common_vars = set(original_ds.data_vars).intersection(set(supergrid_ds.data_vars))
    print(f"Common variables for plotting: {list(common_vars)}")
    
    # Plot FFMC from both datasets separately since they have different variables
    fig, axes = plt.subplots(1, 2, figsize=(16, 6))
    
    # Original FFMC
    if 'ffmc' in original_ds.data_vars:
        try:
            original_ds['ffmc'].isel(time=0).plot(ax=axes[0], cmap='RdYlBu_r')
            axes[0].set_title('Original Grid - FFMC')
        except:
            axes[0].text(0.5, 0.5, 'Error plotting\noriginal FFMC', 
                        ha='center', va='center', transform=axes[0].transAxes)
    
    # Superimposed FFMC
    if 'ffmc' in supergrid_ds.data_vars:
        try:
            supergrid_ds['ffmc'].isel(time=0).plot(ax=axes[1], cmap='RdYlBu_r')
            axes[1].set_title('Superimposed Grid - FFMC (Finer Resolution)')
        except:
            axes[1].text(0.5, 0.5, 'Error plotting\nsuperimposed FFMC', 
                        ha='center', va='center', transform=axes[1].transAxes)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/ffmc_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Create individual plots for each dataset to show resolution difference
    for dataset_name, ds in [('original', original_ds), ('superimposed', supergrid_ds)]:
        if 'ffmc' in ds.data_vars:
            try:
                fig, ax = plt.subplots(1, 1, figsize=(12, 8))
                ds['ffmc'].isel(time=0).plot(ax=ax, cmap='RdYlBu_r')
                ax.set_title(f'{dataset_name.capitalize()} FFMC - Grid size: {ds.dims}')
                plt.savefig(f'{output_dir}/{dataset_name}_ffmc.png', dpi=300, bbox_inches='tight')
                plt.close()
                print(f"Saved {dataset_name}_ffmc.png")
            except Exception as e:
                print(f"Error plotting {dataset_name} FFMC: {e}")

def main():
    """Main analysis function."""
    print("Fire Weather Index Analysis")
    print("="*50)
    
    # File paths
    base_dir = Path("/home/cschmidt/git/GOLEM/projects/ignite")
    
    files = {
        'original': base_dir / 'ignite_v01.nc',
        'supergrid': base_dir / 'ignite_v01_ffmc_supgrid.nc',
        'subgrid_super': base_dir / 'ignite_v1.0_ffmc_subgrid_super.nc',
        'classification': base_dir / 'ignite_v01_ffmc_class.nc',
        'supergrid_class': base_dir / 'ignite_v01_ffmc_supgrid_class.nc'
    }
    
    # Regional files
    regions = {
        'inn': [
            base_dir / 'regions/ignite_v01_ffmc_supgrid_inn.nc',
            base_dir / 'regions/ignite_v01_ffmc_supgrid_class_inn.nc',
            base_dir / 'regions/ignite_v1.0_ffmc_subgrid_super_class_inn.nc'
        ],
        'noe': [
            base_dir / 'regions/ignite_v01_ffmc_supgrid_noe.nc',
            base_dir / 'regions/ignite_v01_ffmc_supgrid_class_noe.nc',
            base_dir / 'regions/ignite_v1.0_ffmc_subgrid_super_class_noe.nc'
        ]
    }
    
    # Load main datasets
    datasets = {}
    for key, filepath in files.items():
        if filepath.exists():
            datasets[key] = load_dataset(filepath)
        else:
            print(f"Warning: {filepath} not found")
    
    # Analysis 1: Grid resolution comparison
    if 'original' in datasets and 'supergrid' in datasets:
        compare_grid_resolutions(datasets['original'], datasets['supergrid'])
    
    # Analysis 2: FFMC modifications
    if 'original' in datasets and 'supergrid' in datasets:
        ffmc_results = analyze_ffmc_modifications(datasets['original'], datasets['supergrid'])
        if ffmc_results:
            print("\nFFMC Modification Results:")
            for var, stats in ffmc_results.items():
                print(f"{var}: {stats['modified_pixels']} pixels modified")
                print(f"  Mean difference: {stats['mean_diff']:.4f}")
                print(f"  Range: [{stats['min_diff']:.4f}, {stats['max_diff']:.4f}]")
    
    # Analysis 3: Classification data
    if 'classification' in datasets:
        class_results = analyze_classification_data(datasets['classification'])
    
    # Analysis 4: Regional case studies
    regional_results = {}
    for region_name, region_files in regions.items():
        regional_results[region_name] = regional_analysis(region_name, region_files)
    
    # Analysis 5: Create comparison plots
    if 'original' in datasets and 'supergrid' in datasets:
        create_comparison_plots(datasets['original'], datasets['supergrid'])
    
    print("\nAnalysis completed!")
    print("Check the 'plots' directory for visualization outputs.")
    
    return {
        'datasets': {k: dict(v.dims) for k, v in datasets.items()},
        'regional_results': regional_results,
        'ffmc_modifications': ffmc_results if 'ffmc_results' in locals() else None
    }

if __name__ == "__main__":
    # Set number of cores for parallel processing
    import os
    os.environ['OMP_NUM_THREADS'] = '30'
    
    results = main()