#!/usr/bin/env python
"""
Extract variables from WRF output files at specific heights and the ground surface.
This script loads a WRF output file, extracts variables at user-specified
heights and at the surface level, and exports the data to a netCDF file.

Includes minimal date verification with fixed string handling.
"""

import os
import sys
import numpy as np
from netCDF4 import Dataset, num2date
import wrf
from wrf import getvar, interplevel, to_np, ALL_TIMES
import multiprocessing as mp
from functools import partial
import time
import datetime


def verify_wrf_times(ncfile):
    """
    Verify time information from WRF output without changing it.
    Simply checks and reports if there are issues.

    Parameters:
    -----------
    ncfile : netCDF4.Dataset
        Open WRF output file
    """
    try:
        # Get times using wrf-python
        times_wrf = getvar(ncfile, "times", timeidx=ALL_TIMES)
        times_np = to_np(times_wrf)

        # Print the time range for verification
        if len(times_np) > 0:
            print(f"Time range: {times_np[0]} to {times_np[-1]} ({len(times_np)} time steps)")

            # Check if times are sequential
            if len(times_np) > 1:
                # Try to detect if times are evenly spaced
                try:
                    # Check if they're datetime strings or objects
                    if isinstance(times_np[0], str):
                        # Parse strings to datetime objects for better comparison
                        datetime_format = '%Y-%m-%d_%H:%M:%S'
                        first_time = datetime.datetime.strptime(times_np[0], datetime_format)
                        second_time = datetime.datetime.strptime(times_np[1], datetime_format)
                        expected_interval = second_time - first_time

                        # Check a few time steps for consistency
                        for i in range(1, min(5, len(times_np))):
                            current = datetime.datetime.strptime(times_np[i], datetime_format)
                            previous = datetime.datetime.strptime(times_np[i-1], datetime_format)
                            interval = current - previous
                            if interval != expected_interval:
                                print(f"Warning: Inconsistent time interval at step {i}: {interval} vs expected {expected_interval}")
                    # Additional checks could be added for other types if needed
                except Exception as e:
                    print(f"Note: Could not fully verify time intervals: {e}")
        else:
            print("Warning: No time steps found in the file")

    except Exception as e:
        print(f"Warning: Could not verify WRF times: {e}")
        # This doesn't affect the extraction process, just a warning


def safe_get_variable(ncfile, var_name, t_idx):
    """
    Safely get a variable from WRF output, handling potential attribute issues.

    Parameters:
    -----------
    ncfile : netCDF4.Dataset
        Open WRF output file
    var_name : str
        Name of the variable to extract
    t_idx : int
        Time index

    Returns:
    --------
    wrf.Variable or None:
        The requested variable or None if not found/error
    """
    try:
        var_3d = getvar(ncfile, var_name, timeidx=t_idx)
        return var_3d
    except Exception as e:
        print(f"  Warning: Variable {var_name} not found or error: {e}")
        return None


def get_surface_value(ncfile, var_name, t_idx):
    """
    Get the surface (ground level) value for a variable.

    Parameters:
    -----------
    ncfile : netCDF4.Dataset
        Open WRF output file
    var_name : str
        Name of the variable to extract
    t_idx : int
        Time index

    Returns:
    --------
    numpy.ndarray or None:
        2D array of surface values or None if not available
    """
    try:
        # For 3D variables, we need to get the lowest level (k=0)
        # First check if variable exists in the WRF file
        var_3d = safe_get_variable(ncfile, var_name, t_idx)

        if var_3d is None:
            return None

        # Check if this is a 3D variable (has a vertical dimension)
        if len(var_3d.shape) > 2:
            # For 3D variables, take the first vertical level (usually closest to surface)
            surface_value = to_np(var_3d[0, :, :])
        else:
            # For 2D variables, use as is
            surface_value = to_np(var_3d)

        return surface_value

    except Exception as e:
        print(f"  Warning: Could not get surface value for {var_name}: {e}")
        return None


def safe_get_attributes(var_3d):
    """
    Safely extract attributes from a WRF variable, handling problematic types.

    Parameters:
    -----------
    var_3d : wrf.Variable
        Variable to extract attributes from

    Returns:
    --------
    dict:
        Dictionary of attribute name/value pairs
    """
    var_attrs = {}

    # Safe attribute types that can be directly stored in netCDF4
    safe_types = (str, int, float, bool, np.int8, np.int16, np.int32, np.int64,
                 np.uint8, np.uint16, np.uint32, np.uint64, np.float32, np.float64)

    for attr_name in var_3d.attrs:
        if attr_name not in ['coordinates', 'grid_mapping', 'cell_methods', 'time', 'projection']:
            attr_value = var_3d.attrs[attr_name]

            # Convert non-safe types to strings
            if not isinstance(attr_value, safe_types):
                attr_value = str(attr_value)

            var_attrs[attr_name] = attr_value

    return var_attrs


def process_timestep(wrfout_file, variables, heights, t_idx, include_surface=True):
    """
    Process all variables for a single time step.

    Parameters:
    -----------
    wrfout_file : str
        Path to WRF output file
    variables : list
        List of variable names to extract
    heights : list
        List of heights in meters to extract variables at
    t_idx : int
        Time index to process
    include_surface : bool
        Whether to include surface level values

    Returns:
    --------
    dict:
        Dictionary of results containing processed data
    """
    try:
        print(f"Processing time step {t_idx+1}")

        # Open the file for this process only
        ncfile = Dataset(wrfout_file, 'r')

        # Get the relevant dimensions for pre-allocation
        lats, lons = getvar(ncfile, "lat"), getvar(ncfile, "lon")
        shape = (lats.shape[0], lats.shape[1])

        # Get the 3D height (AGL) for this time step
        z = getvar(ncfile, "height_agl", timeidx=t_idx)

        # Dictionary to store results for this time step
        results = {}

        # Process each variable
        for var_name in variables:
            try:
                # Get the variable for this time step
                var_3d = safe_get_variable(ncfile, var_name, t_idx)

                if var_3d is None:
                    continue

                # Get attributes if this is the first time we're processing this variable
                var_attrs = safe_get_attributes(var_3d)

                # Get surface value if requested
                surface_value = None
                if include_surface:
                    surface_value = get_surface_value(ncfile, var_name, t_idx)

                # For 3D height interpolation
                if len(var_3d.shape) > 2:  # Check if it's a 3D variable
                    # Pre-allocate array for all heights
                    var_data = np.zeros((len(heights), shape[0], shape[1]), dtype=np.float64)

                    # Interpolate to each height level
                    for h_idx, height in enumerate(heights):
                        var_at_height = interplevel(var_3d, z, height)
                        var_data[h_idx, :, :] = to_np(var_at_height)

                    # Store results for this variable
                    results[var_name] = {
                        'data': var_data,
                        'attrs': var_attrs,
                        'surface': surface_value
                    }
                else:
                    # For 2D variables, just store the original values (no height interpolation)
                    # We'll still create a placeholder for consistency in the output
                    var_data = np.zeros((len(heights), shape[0], shape[1]), dtype=np.float64)
                    for h_idx in range(len(heights)):
                        var_data[h_idx, :, :] = to_np(var_3d)

                    results[var_name] = {
                        'data': var_data,
                        'attrs': var_attrs,
                        'surface': to_np(var_3d)  # For 2D variables, surface is the same as the variable
                    }

            except Exception as e:
                print(f"  Error processing {var_name} at time {t_idx}: {e}")

        # Close the file before returning
        ncfile.close()

        return t_idx, results

    except Exception as e:
        print(f"Error in process_timestep for time {t_idx}: {e}")
        if 'ncfile' in locals() and ncfile:
            ncfile.close()
        return t_idx, {}


def extract_variables_at_heights(wrfout_file, variables, heights, output_file, n_processes=None, include_surface=True):
    """
    Extract WRF variables at specific heights and surface level, saving to a netCDF file.
    Uses parallel processing for improved performance.

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
    n_processes : int, optional
        Number of processes to use for parallel processing. Default is None,
        which uses the number of available CPU cores minus 1.
    include_surface : bool, optional
        Whether to include surface (ground level) data. Default is True.

    Returns:
    --------
    None
    """
    start_time = time.time()
    print(f"Opening WRF output file: {wrfout_file}")

    if n_processes is None:
        n_processes = max(1, mp.cpu_count() - 1)
    print(f"Using {n_processes} processes for parallel extraction")
    print(f"Including surface level: {include_surface}")

    try:
        # Open the WRF output file to get dimensions and create output file
        with Dataset(wrfout_file, 'r') as ncfile:
            # Verify dates without modifying them
            verify_wrf_times(ncfile)

            # Get time, latitude, and longitude
            times = getvar(ncfile, "times", timeidx=ALL_TIMES)
            lats, lons = getvar(ncfile, "lat"), getvar(ncfile, "lon")

            # Get shape for pre-allocation
            shape = (lats.shape[0], lats.shape[1])
            n_times = len(times)

            # Get height info to be used by all processes
            time_values = to_np(times)
            lat_values = to_np(lats)
            lon_values = to_np(lons)

            # Try to get time units and calendar for proper time representation
            if hasattr(times, 'units'):
                time_units = times.units
            else:
                time_units = 'hours since 1900-01-01 00:00:00'

            if hasattr(times, 'calendar'):
                calendar = times.calendar
            else:
                calendar = 'standard'

        # Create output file
        with Dataset(output_file, 'w', format='NETCDF4') as outfile:
            # Set up dimensions in the output file
            outfile.createDimension('time', n_times)
            outfile.createDimension('height', len(heights))
            outfile.createDimension('south_north', shape[0])
            outfile.createDimension('west_east', shape[1])

            # Create dimension variables
            time_var = outfile.createVariable('time', 'f8', ('time',))
            time_var.units = time_units
            time_var.calendar = calendar
            time_var.standard_name = "time"
            time_var[:] = np.arange(n_times)  # Use simple indices to avoid date conversion issues

            # Create a character array to store time strings
            # Use a fixed-length character array instead of a string variable
            str_len = 20  # Length to fit YYYY-MM-DD_HH:MM:SS format
            outfile.createDimension('str_len', str_len)
            time_str_var = outfile.createVariable('time_str', 'S1', ('time', 'str_len'))
            time_str_var.units = "YYYY-MM-DD_HH:MM:SS format"
            time_str_var.long_name = "Time as formatted string"

            # Fill the character array
            for i, t in enumerate(time_values):
                t_str = str(t)
                for j, c in enumerate(t_str[:str_len]):
                    time_str_var[i, j] = c

            height_var = outfile.createVariable('height', 'f8', ('height',))
            height_var.units = 'meters'
            height_var.description = 'Heights above ground level'
            height_var[:] = heights

            lat_var = outfile.createVariable('lat', 'f8', ('south_north', 'west_east'))
            lat_var.units = 'degrees_north'
            lat_var.description = 'latitude'
            lat_var[:] = lat_values

            lon_var = outfile.createVariable('lon', 'f8', ('south_north', 'west_east'))
            lon_var.units = 'degrees_east'
            lon_var.description = 'longitude'
            lon_var[:] = lon_values

        # Use a process pool for parallel processing of time steps
        with mp.Pool(processes=n_processes) as pool:
            # Prepare the function for parallel execution
            process_func = partial(process_timestep, wrfout_file, variables, heights, include_surface=include_surface)

            # Process time steps in parallel
            time_indices = list(range(n_times))
            results = pool.map(process_func, time_indices)

        # Now that processing is complete, we need to write the results to the output file
        with Dataset(output_file, 'a') as outfile:
            # Collect all variables that were found
            found_variables = set()
            for t_idx, time_result in results:
                found_variables.update(time_result.keys())

            # Create data arrays for found variables
            var_data = {var: np.zeros((n_times, len(heights), shape[0], shape[1])) for var in found_variables}
            var_attrs = {var: None for var in found_variables}

            # If including surface level, create surface variables
            if include_surface:
                surface_data = {var: np.zeros((n_times, shape[0], shape[1])) for var in found_variables}

            # Flag to track if any variable was successfully processed
            any_variable_processed = False

            # Populate data arrays from results
            for t_idx, time_result in results:
                if not time_result:  # Skip if no results for this time step
                    continue

                for var_name, var_info in time_result.items():
                    var_data[var_name][t_idx] = var_info['data']
                    if include_surface and var_info['surface'] is not None:
                        surface_data[var_name][t_idx] = var_info['surface']
                    if var_attrs[var_name] is None:
                        var_attrs[var_name] = var_info['attrs']
                    any_variable_processed = True

            if not any_variable_processed:
                print("Warning: No variables were successfully processed!")
                return

            # Create variables and write data for found variables
            var_dims = ('time', 'height', 'south_north', 'west_east')
            surface_dims = ('time', 'south_north', 'west_east')

            for var_name in found_variables:
                if var_attrs[var_name] is not None:  # Only create variables we have data for
                    print(f"Creating output variable: {var_name}")

                    # Create height-interpolated variable
                    out_var = outfile.createVariable(var_name, 'f8', var_dims,
                                                    zlib=True, complevel=1)

                    # Copy attributes safely
                    for attr_name, attr_value in var_attrs[var_name].items():
                        try:
                            setattr(out_var, attr_name, attr_value)
                        except Exception as e:
                            print(f"Warning: Couldn't set attribute {attr_name} for {var_name}: {e}")

                    # Write data
                    out_var[:] = var_data[var_name]

                    # Create surface variable if requested
                    if include_surface and var_name in surface_data:
                        surf_var_name = f"{var_name}_surface"
                        surf_var = outfile.createVariable(surf_var_name, 'f8', surface_dims,
                                                        zlib=True, complevel=1)

                        # Copy attributes to surface variable too
                        for attr_name, attr_value in var_attrs[var_name].items():
                            try:
                                setattr(surf_var, attr_name, attr_value)
                            except Exception as e:
                                print(f"Warning: Couldn't set attribute {attr_name} for {surf_var_name}: {e}")

                        # Add surface-specific attributes
                        surf_var.description = f"Surface level values for {var_name}"

                        # Write surface data
                        surf_var[:] = surface_data[var_name]

                    print(f"Successfully wrote data for {var_name}")

        elapsed_time = time.time() - start_time
        print(f"Extraction completed in {elapsed_time:.2f} seconds")
        print(f"Output saved to: {output_file}")

    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


def main():
    """Main function to parse arguments and call extraction function."""
    import argparse

    parser = argparse.ArgumentParser(description='Extract WRF variables at specific heights and surface level')
    parser.add_argument('wrfout_file', help='Path to WRF output file')
    parser.add_argument('--vars', '-v', nargs='+', required=True,
                        help='Variables to extract (e.g., ua va tc rh)')
    parser.add_argument('--heights', '-z', nargs='+', type=float, required=True,
                        help='Heights in meters to extract variables at')
    parser.add_argument('--output', '-o', default=None,
                        help='Output netCDF file path')
    parser.add_argument('--processes', '-p', type=int, default=None,
                        help='Number of processes to use (default: CPU count - 1)')
    parser.add_argument('--no-surface', action='store_true',
                        help='Skip extraction of surface (ground level) data')

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
    print(f"Include surface: {not args.no_surface}")
    print(f"Output file: {args.output}")
    print(f"Processes:   {args.processes or 'auto'}")
    print("======================\n")

    # Perform the extraction
    extract_variables_at_heights(args.wrfout_file, args.vars, args.heights,
                                args.output, args.processes,
                                include_surface=not args.no_surface)

    return 0


if __name__ == "__main__":
    sys.exit(main())
