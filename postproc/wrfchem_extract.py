#!/usr/bin/env python
"""
Extract variables from WRF output files at specific heights.
This script loads a WRF output file, extracts variables at user-specified
heights, and exports the data to a netCDF file.
"""

import os
import sys
import numpy as np
import xarray as xr
from netCDF4 import Dataset
import wrf
from wrf import getvar, interplevel, to_np, ALL_TIMES

def extract_variables_at_heights(wrfout_file, variables, heights, output_file):
    """
    Extract WRF variables at specific heights and save to a new netCDF file.

    Parameters:
    -----------
    wrfout_file : str
        Path to the WRF output file
    variables : list
        List of variable names to extract (e.g., ["ua", "va", "tc", "rh"])
    heights : list
        List of heights in meters to extract variables at
    output_file : str
        Path to the output netCDF file

    Returns:
    --------
    None
    """
    print(f"Opening WRF output file: {wrfout_file}")

    try:
        # Open the WRF output file
        ncfile = Dataset(wrfout_file)

        # Create output file
        outfile = Dataset(output_file, 'w', format='NETCDF4')

        # Get time, latitude, and longitude
        times = getvar(ncfile, "times", timeidx=ALL_TIMES)
        lats, lons = getvar(ncfile, "lat"), getvar(ncfile, "lon")

        # Set up dimensions in the output file
        outfile.createDimension('time', len(times))
        outfile.createDimension('height', len(heights))
        outfile.createDimension('south_north', lats.shape[0])
        outfile.createDimension('west_east', lats.shape[1])

        # Create dimension variables
        time_var = outfile.createVariable('time', 'f8', ('time',))
        time_var.units = 'hours since initial time'
        time_var[:] = np.arange(len(times))

        height_var = outfile.createVariable('height', 'f8', ('height',))
        height_var.units = 'meters'
        height_var.description = 'Heights above ground level'
        height_var[:] = heights

        lat_var = outfile.createVariable('lat', 'f8', ('south_north', 'west_east'))
        lat_var.units = 'degrees_north'
        lat_var.description = 'latitude'
        lat_var[:] = to_np(lats)

        lon_var = outfile.createVariable('lon', 'f8', ('south_north', 'west_east'))
        lon_var.units = 'degrees_east'
        lon_var.description = 'longitude'
        lon_var[:] = to_np(lons)

        # Process each time step
        for t_idx in range(len(times)):
            print(f"Processing time step {t_idx+1}/{len(times)}")

            # Get the 3D height (AGL) for this time step
            z = getvar(ncfile, "height_agl", timeidx=t_idx)

            # Extract each requested variable
            for var_name in variables:
                print(f"  Extracting variable: {var_name}")

                # Check if variable exists for this time step
                try:
                    var_3d = getvar(ncfile, var_name, timeidx=t_idx)
                except:
                    print(f"    Warning: Variable {var_name} not found. Skipping.")
                    continue

                # Create the output variable if it doesn't exist yet
                if f"{var_name}" not in outfile.variables:
                    var_dims = ('time', 'height', 'south_north', 'west_east')
                    out_var = outfile.createVariable(var_name, 'f8', var_dims)

                    # Copy attributes from the original variable
                    for attr_name in var_3d.attrs:
                        if attr_name not in ['coordinates', 'grid_mapping', 'cell_methods', 'time']:
                            setattr(out_var, attr_name, var_3d.attrs[attr_name])

                # Interpolate to each height level
                for h_idx, height in enumerate(heights):
                    print(f"    Interpolating to height: {height}m")
                    var_at_height = interplevel(var_3d, z, height)
                    outfile.variables[var_name][t_idx, h_idx, :, :] = to_np(var_at_height)

        # Close files
        ncfile.close()
        outfile.close()
        print(f"Output saved to: {output_file}")

    except Exception as e:
        print(f"Error: {e}")
        if 'ncfile' in locals() and ncfile:
            ncfile.close()
        if 'outfile' in locals() and outfile:
            outfile.close()
        sys.exit(1)

def main():
    """Main function to parse arguments and call extraction function."""
    import argparse

    parser = argparse.ArgumentParser(description='Extract WRF variables at specific heights')
    parser.add_argument('wrfout_file', help='Path to WRF output file')
    parser.add_argument('--vars', '-v', nargs='+', required=True,
                        help='Variables to extract (e.g., ua va tc rh)')
    parser.add_argument('--heights', '-z', nargs='+', type=float, required=True,
                        help='Heights in meters to extract variables at')
    parser.add_argument('--output', '-o', default=None,
                        help='Output netCDF file path')

    args = parser.parse_args()

    # Set default output name if not provided
    if args.output is None:
        base_dir = os.path.dirname(args.wrfout_file)
        base_name = os.path.basename(args.wrfout_file).replace('.nc', '').replace('wrfout_', '')
        args.output = os.path.join(base_dir, f'extracted_{base_name}.nc')

    # Print summary of extraction parameters
    print("\nWRF Variable Extraction")
    print("======================")
    print(f"Input file:  {args.wrfout_file}")
    print(f"Variables:   {', '.join(args.vars)}")
    print(f"Heights (m): {', '.join(map(str, args.heights))}")
    print(f"Output file: {args.output}")
    print("======================\n")

    # Perform the extraction
    extract_variables_at_heights(args.wrfout_file, args.vars, args.heights, args.output)

    return 0

if __name__ == "__main__":
    sys.exit(main())
