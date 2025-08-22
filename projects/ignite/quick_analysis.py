#!/usr/bin/env python3
"""
Quick Fire Weather Index Analysis
Focus on key findings about superimposition and regional differences
"""

import xarray as xr
import numpy as np
import matplotlib.pyplot as plt
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

def quick_dataset_summary(filepath):
    """Quick summary of dataset without loading all data."""
    print(f"\nAnalyzing: {Path(filepath).name}")
    try:
        ds = xr.open_dataset(filepath)
        print(f"  Dimensions: {dict(ds.dims)}")
        print(f"  Variables: {list(ds.data_vars)}")
        
        # Calculate total grid points
        spatial_dims = [dim for dim in ds.dims if dim in ['x', 'y', 'easting', 'northing']]
        if len(spatial_dims) >= 2:
            total_points = np.prod([ds.dims[dim] for dim in spatial_dims])
            print(f"  Total spatial points: {total_points:,}")
        
        # Quick stats for FFMC if present
        ffmc_vars = [var for var in ds.data_vars if 'ffmc' in var.lower()]
        for var in ffmc_vars:
            try:
                # Sample first timestep only
                data = ds[var].isel(time=0)
                print(f"  {var} stats (t=0): min={data.min().values:.2f}, max={data.max().values:.2f}, mean={data.mean().values:.2f}")
            except:
                print(f"  {var}: Unable to compute quick stats")
        
        ds.close()
        return dict(ds.dims), list(ds.data_vars)
    except Exception as e:
        print(f"  Error: {e}")
        return None, None

def main():
    print("Fire Weather Index Quick Analysis")
    print("="*50)
    
    base_dir = Path("/home/cschmidt/git/GOLEM/projects/ignite")
    
    # Main files analysis
    files = {
        'Original coarse grid': base_dir / 'ignite_v01.nc',
        'Superimposed fine grid': base_dir / 'ignite_v01_ffmc_supgrid.nc', 
        'Subgrid super': base_dir / 'ignite_v1.0_ffmc_subgrid_super.nc',
        'Classification': base_dir / 'ignite_v01_ffmc_class.nc',
        'Superimposed classification': base_dir / 'ignite_v01_ffmc_supgrid_class.nc'
    }
    
    results = {}
    for name, filepath in files.items():
        if filepath.exists():
            dims, vars = quick_dataset_summary(filepath)
            results[name] = {'dims': dims, 'vars': vars}
    
    # Regional analysis
    print("\n" + "="*50)
    print("REGIONAL ANALYSIS")
    print("="*50)
    
    regions = {
        'Inn valley': ['ignite_v01_ffmc_supgrid_inn.nc', 'ignite_v01_ffmc_supgrid_class_inn.nc'],
        'North-East (NOE)': ['ignite_v01_ffmc_supgrid_noe.nc', 'ignite_v01_ffmc_supgrid_class_noe.nc']
    }
    
    for region_name, files_list in regions.items():
        print(f"\nRegion: {region_name}")
        print("-" * 30)
        for filename in files_list:
            filepath = base_dir / 'regions' / filename
            if filepath.exists():
                quick_dataset_summary(filepath)
    
    # Summary findings
    print("\n" + "="*50)
    print("KEY FINDINGS")
    print("="*50)
    
    if 'Original coarse grid' in results and 'Superimposed fine grid' in results:
        orig_dims = results['Original coarse grid']['dims']
        super_dims = results['Superimposed fine grid']['dims']
        
        print(f"1. Grid Resolution Enhancement:")
        for dim in ['x', 'y']:
            if dim in orig_dims and dim in super_dims:
                ratio = super_dims[dim] / orig_dims[dim] 
                print(f"   - {dim} dimension: {orig_dims[dim]} → {super_dims[dim]} (×{ratio:.1f})")
        
        orig_points = orig_dims.get('x', 1) * orig_dims.get('y', 1)
        super_points = super_dims.get('x', 1) * super_dims.get('y', 1)
        enhancement = super_points / orig_points
        print(f"   - Total spatial enhancement: ×{enhancement:.1f}")
    
    print(f"\n2. Available Data Types:")
    for name, data in results.items():
        if data['vars']:
            print(f"   - {name}: {', '.join([v for v in data['vars'] if 'lambert' not in v and 'crs' not in v])}")
    
    print(f"\n3. Regional Data:")
    print(f"   - Two regions identified: Inn valley and North-East (NOE)")
    print(f"   - Both regions have superimposed grid and classification data")
    
    print(f"\n4. Temporal Coverage:")
    if results:
        time_dim = None
        for data in results.values():
            if data['dims'] and 'time' in data['dims']:
                time_dim = data['dims']['time']
                break
        if time_dim:
            print(f"   - {time_dim} time steps available")

if __name__ == "__main__":
    main()