#!/usr/bin/env python3
"""
Comprehensive Fire Weather Index Analysis
Analyzing FFMC superimposition effectiveness and regional case studies
Utilizing parallel processing with 30 cores
"""

import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from multiprocessing import Pool, cpu_count
import pandas as pd
from pathlib import Path
import warnings
from functools import partial
import os
warnings.filterwarnings('ignore')

# Set number of cores
N_CORES = min(30, cpu_count())
os.environ['OMP_NUM_THREADS'] = str(N_CORES)

def load_and_analyze_single_file(filepath):
    """Load single file and extract key metrics (for parallel processing)."""
    try:
        ds = xr.open_dataset(filepath)
        
        result = {
            'file': str(filepath),
            'filename': Path(filepath).name,
            'dimensions': dict(ds.dims),
            'variables': list(ds.data_vars),
            'coords': list(ds.coords)
        }
        
        # Analyze FFMC-related variables
        ffmc_vars = [var for var in ds.data_vars if 'ffmc' in var.lower()]
        result['ffmc_analysis'] = {}
        
        for var in ffmc_vars:
            data = ds[var]
            
            # Sample multiple time steps for temporal analysis
            time_samples = [0, len(ds.time)//4, len(ds.time)//2, 3*len(ds.time)//4, -1]
            
            stats = {}
            for i, t_idx in enumerate(time_samples):
                try:
                    sample = data.isel(time=t_idx)
                    stats[f't{i}'] = {
                        'mean': float(sample.mean()),
                        'std': float(sample.std()),
                        'min': float(sample.min()),
                        'max': float(sample.max()),
                        'valid_count': int((~np.isnan(sample)).sum())
                    }
                except:
                    stats[f't{i}'] = None
            
            result['ffmc_analysis'][var] = {
                'shape': data.shape,
                'dtype': str(data.dtype),
                'temporal_stats': stats
            }
        
        ds.close()
        return result
        
    except Exception as e:
        return {
            'file': str(filepath),
            'filename': Path(filepath).name,
            'error': str(e)
        }

def analyze_classification_patterns(class_file):
    """Analyze spatial patterns in classification data."""
    try:
        ds = xr.open_dataset(class_file)
        
        # Find classification variable
        class_vars = [var for var in ds.data_vars if 'class' in var.lower()]
        if not class_vars:
            return None
            
        class_var = class_vars[0]
        class_data = ds[class_var]
        
        results = {}
        
        # Analyze first time step
        data_t0 = class_data.isel(time=0)
        unique_classes = np.unique(data_t0.values[~np.isnan(data_t0.values)])
        
        results['unique_classes'] = unique_classes.tolist()
        results['class_distribution'] = {}
        
        total_pixels = (~np.isnan(data_t0)).sum().values
        
        for cls in unique_classes:
            count = (data_t0 == cls).sum().values
            results['class_distribution'][int(cls)] = {
                'count': int(count),
                'percentage': float(count / total_pixels * 100)
            }
        
        # Analyze temporal stability
        temporal_changes = []
        for t in range(0, min(len(ds.time), 100), 10):  # Sample every 10th timestep
            data_t = class_data.isel(time=t)
            class_counts = {int(cls): int((data_t == cls).sum()) for cls in unique_classes}
            temporal_changes.append(class_counts)
        
        results['temporal_stability'] = temporal_changes
        results['filename'] = Path(class_file).name
        
        ds.close()
        return results
        
    except Exception as e:
        return {'error': str(e), 'filename': Path(class_file).name}

def create_regional_comparison_plot(inn_file, noe_file, output_dir):
    """Create comparison plots for the two regions."""
    fig, axes = plt.subplots(2, 3, figsize=(18, 12))
    
    regions = [
        ('Inn Valley', inn_file, axes[0]),
        ('North-East (NOE)', noe_file, axes[1])
    ]
    
    for region_name, filepath, ax_row in regions:
        try:
            ds = xr.open_dataset(filepath)
            
            # Find FFMC variable
            ffmc_vars = [var for var in ds.data_vars if 'ffmc' in var.lower() and 'class' not in var.lower()]
            if ffmc_vars:
                ffmc_data = ds[ffmc_vars[0]]
                
                # Plot different time periods
                times = [0, len(ds.time)//2, -1]
                time_labels = ['Early Period', 'Mid Period', 'Late Period']
                
                for i, (time_idx, time_label) in enumerate(zip(times, time_labels)):
                    im = ffmc_data.isel(time=time_idx).plot(ax=ax_row[i], cmap='RdYlBu_r', add_colorbar=False)
                    ax_row[i].set_title(f'{region_name}\n{time_label}')
                    ax_row[i].set_xlabel('Grid X')
                    ax_row[i].set_ylabel('Grid Y')
                
                # Add colorbar for the row
                plt.colorbar(im, ax=ax_row, orientation='vertical', shrink=0.6, pad=0.02)
            
            ds.close()
            
        except Exception as e:
            for ax in ax_row:
                ax.text(0.5, 0.5, f'Error loading\n{region_name}\n{str(e)}', 
                       ha='center', va='center', transform=ax.transAxes)
    
    plt.tight_layout()
    plt.savefig(f'{output_dir}/regional_comparison.png', dpi=300, bbox_inches='tight')
    plt.close()
    print("Saved regional_comparison.png")

def analyze_superimposition_effectiveness(original_file, super_file, output_dir):
    """Analyze how well the superimposition worked."""
    
    try:
        # Load original coarse data
        ds_orig = xr.open_dataset(original_file)
        # Load superimposed fine data  
        ds_super = xr.open_dataset(super_file)
        
        orig_ffmc = ds_orig['ffmc']
        super_ffmc = ds_super['ffmc']
        
        # Compare spatial extents and ranges
        results = {
            'original_grid_size': f"{ds_orig.dims['x']} × {ds_orig.dims['y']}",
            'superimposed_grid_size': f"{ds_super.dims['x']} × {ds_super.dims['y']}",
            'resolution_enhancement': (ds_super.dims['x'] * ds_super.dims['y']) / (ds_orig.dims['x'] * ds_orig.dims['y']),
            'temporal_comparison': {}
        }
        
        # Temporal analysis - compare statistics over time
        time_samples = np.linspace(0, len(ds_orig.time)-1, 20, dtype=int)
        
        for i, t in enumerate(time_samples):
            orig_t = orig_ffmc.isel(time=t)
            super_t = super_ffmc.isel(time=t)
            
            results['temporal_comparison'][i] = {
                'original': {
                    'mean': float(orig_t.mean()),
                    'std': float(orig_t.std()),
                    'range': float(orig_t.max() - orig_t.min())
                },
                'superimposed': {
                    'mean': float(super_t.mean()),
                    'std': float(super_t.std()),
                    'range': float(super_t.max() - super_t.min())
                }
            }
        
        # Create comparison plot
        fig, axes = plt.subplots(2, 2, figsize=(16, 12))
        
        # Plot original
        orig_ffmc.isel(time=0).plot(ax=axes[0,0], cmap='RdYlBu_r')
        axes[0,0].set_title(f'Original Grid\n{results["original_grid_size"]} points')
        
        # Plot superimposed (subsample for visualization)
        super_sub = super_ffmc.isel(time=0, x=slice(None, None, 8), y=slice(None, None, 8))
        super_sub.plot(ax=axes[0,1], cmap='RdYlBu_r') 
        axes[0,1].set_title(f'Superimposed Grid (subsampled)\n{results["superimposed_grid_size"]} points')
        
        # Time series comparison
        orig_means = [results['temporal_comparison'][i]['original']['mean'] for i in range(20)]
        super_means = [results['temporal_comparison'][i]['superimposed']['mean'] for i in range(20)]
        
        axes[1,0].plot(orig_means, 'b-', label='Original', linewidth=2)
        axes[1,0].plot(super_means, 'r-', label='Superimposed', linewidth=2)
        axes[1,0].set_xlabel('Time Sample')
        axes[1,0].set_ylabel('Mean FFMC')
        axes[1,0].set_title('Temporal Mean Comparison')
        axes[1,0].legend()
        axes[1,0].grid(True, alpha=0.3)
        
        # Standard deviation comparison
        orig_stds = [results['temporal_comparison'][i]['original']['std'] for i in range(20)]
        super_stds = [results['temporal_comparison'][i]['superimposed']['std'] for i in range(20)]
        
        axes[1,1].plot(orig_stds, 'b-', label='Original', linewidth=2)
        axes[1,1].plot(super_stds, 'r-', label='Superimposed', linewidth=2)
        axes[1,1].set_xlabel('Time Sample')
        axes[1,1].set_ylabel('FFMC Standard Deviation')
        axes[1,1].set_title('Temporal Variability Comparison')
        axes[1,1].legend()
        axes[1,1].grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/superimposition_effectiveness.png', dpi=300, bbox_inches='tight')
        plt.close()
        
        ds_orig.close()
        ds_super.close()
        
        return results
        
    except Exception as e:
        return {'error': str(e)}

def main():
    print("Comprehensive Fire Weather Index Analysis")
    print("=" * 60)
    print(f"Using {N_CORES} cores for parallel processing")
    
    base_dir = Path("/home/cschmidt/git/GOLEM/projects/ignite")
    output_dir = base_dir / "analysis_results"
    output_dir.mkdir(exist_ok=True)
    
    # Define all files to analyze
    all_files = [
        base_dir / 'ignite_v01.nc',
        base_dir / 'ignite_v01_ffmc_supgrid.nc',
        base_dir / 'ignite_v1.0_ffmc_subgrid_super.nc',
        base_dir / 'ignite_v01_ffmc_class.nc',
        base_dir / 'ignite_v01_ffmc_supgrid_class.nc',
        base_dir / 'regions/ignite_v01_ffmc_supgrid_inn.nc',
        base_dir / 'regions/ignite_v01_ffmc_supgrid_class_inn.nc',
        base_dir / 'regions/ignite_v1.0_ffmc_subgrid_super_class_inn.nc',
        base_dir / 'regions/ignite_v01_ffmc_supgrid_noe.nc',
        base_dir / 'regions/ignite_v01_ffmc_supgrid_class_noe.nc',
        base_dir / 'regions/ignite_v1.0_ffmc_subgrid_super_class_noe.nc'
    ]
    
    # Filter existing files
    existing_files = [f for f in all_files if f.exists()]
    print(f"Found {len(existing_files)} data files")
    
    print("\n1. Parallel analysis of all datasets...")
    
    # Parallel analysis of all files
    with Pool(N_CORES) as pool:
        file_results = pool.map(load_and_analyze_single_file, existing_files)
    
    print(f"Completed analysis of {len(file_results)} files")
    
    print("\n2. Classification analysis...")
    
    # Analyze classification files
    class_files = [f for f in existing_files if 'class' in str(f)]
    classification_results = []
    
    for cf in class_files:
        result = analyze_classification_patterns(cf)
        if result:
            classification_results.append(result)
    
    print(f"Analyzed {len(classification_results)} classification datasets")
    
    print("\n3. Superimposition effectiveness analysis...")
    
    # Analyze superimposition effectiveness
    original_file = base_dir / 'ignite_v01.nc'
    super_file = base_dir / 'ignite_v01_ffmc_supgrid.nc'
    
    if original_file.exists() and super_file.exists():
        superimposition_results = analyze_superimposition_effectiveness(
            original_file, super_file, output_dir
        )
        print("Superimposition analysis completed")
    
    print("\n4. Regional comparison analysis...")
    
    # Regional comparison
    inn_file = base_dir / 'regions/ignite_v01_ffmc_supgrid_inn.nc'
    noe_file = base_dir / 'regions/ignite_v01_ffmc_supgrid_noe.nc'
    
    if inn_file.exists() and noe_file.exists():
        create_regional_comparison_plot(inn_file, noe_file, output_dir)
        print("Regional comparison plots created")
    
    # Generate comprehensive report
    print("\n5. Generating comprehensive report...")
    
    report = []
    report.append("FIRE WEATHER INDEX ANALYSIS REPORT")
    report.append("=" * 50)
    
    # Grid enhancement summary
    if 'superimposition_results' in locals() and 'resolution_enhancement' in superimposition_results:
        enhancement = superimposition_results['resolution_enhancement']
        report.append(f"\nGRID ENHANCEMENT:")
        report.append(f"- Resolution improvement: {enhancement:.1f}×")
        report.append(f"- Original grid: {superimposition_results['original_grid_size']}")
        report.append(f"- Enhanced grid: {superimposition_results['superimposed_grid_size']}")
    
    # Classification summary
    report.append(f"\nCLASSIFICATION ANALYSIS:")
    for cls_result in classification_results:
        if 'unique_classes' in cls_result:
            report.append(f"- {cls_result['filename']}: {len(cls_result['unique_classes'])} classes")
            for cls, dist in cls_result['class_distribution'].items():
                report.append(f"  Class {cls}: {dist['percentage']:.1f}% ({dist['count']} pixels)")
    
    # File summary
    report.append(f"\nDATASET SUMMARY:")
    for result in file_results:
        if 'error' not in result:
            total_points = 1
            for dim, size in result['dimensions'].items():
                if dim in ['x', 'y', 'easting', 'northing']:
                    total_points *= size
            
            report.append(f"- {result['filename']}: {total_points:,} spatial points, {result['dimensions'].get('time', 'N/A')} timesteps")
    
    # Write report
    with open(output_dir / 'analysis_report.txt', 'w') as f:
        f.write('\n'.join(report))
    
    print(f"\nAnalysis complete! Results saved to {output_dir}")
    print(f"- analysis_report.txt: Comprehensive text report")
    print(f"- superimposition_effectiveness.png: Grid comparison plots") 
    print(f"- regional_comparison.png: Inn vs NOE comparison")

if __name__ == "__main__":
    main()