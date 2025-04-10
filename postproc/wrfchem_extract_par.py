#!/usr/bin/env python
"""
Extract variables from WRF output files at specific heights and the ground surface.
This script loads a WRF output file, extracts variables at user-specified
heights and at the surface level, and exports the data to a netCDF file.

Configuration can be provided via command line or through a YAML config file.
"""

import os
import sys
import glob
import numpy as np
from netCDF4 import Dataset, num2date
import wrf
from wrf import getvar, interplevel, to_np, ALL_TIMES
import multiprocessing as mp
from functools import partial
import time
import datetime
import yaml
import concurrent.futures
import itertools
import queue
import threading
import psutil


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


def process_variable_at_time(args):
    """
    Process a single variable at a specific time step.
    
    Parameters:
    -----------
    args : tuple
        Contains (wrfout_file, var_name, t_idx, heights, include_surface, shape)
    
    Returns:
    --------
    tuple:
        (var_name, t_idx, result_dict)
        where result_dict has 'data', 'attrs', and 'surface' keys
    """
    wrfout_file, var_name, t_idx, heights, include_surface, shape = args
    
    try:
        # Open the file to access the data
        with Dataset(wrfout_file, 'r') as ncfile:
            # Get the variable for this time step
            var_3d = safe_get_variable(ncfile, var_name, t_idx)
            
            if var_3d is None:
                return (var_name, t_idx, None)
                
            # Get attributes
            var_attrs = safe_get_attributes(var_3d)
            
            # Get surface value if requested
            surface_value = None
            if include_surface:
                surface_value = get_surface_value(ncfile, var_name, t_idx)
            
            # Get 3D height for this time step
            z = getvar(ncfile, "height_agl", timeidx=t_idx)
            
            # Process data based on dimensionality
            if len(var_3d.shape) > 2:  # 3D variable
                # Pre-allocate array for all heights
                var_data = np.zeros((len(heights), shape[0], shape[1]), dtype=np.float64)
                
                # Interpolate to each height level
                for h_idx, height in enumerate(heights):
                    var_at_height = interplevel(var_3d, z, height)
                    var_data[h_idx, :, :] = to_np(var_at_height)
            else:  # 2D variable
                # For 2D variables, just store the original values at all heights
                var_data = np.zeros((len(heights), shape[0], shape[1]), dtype=np.float64)
                for h_idx in range(len(heights)):
                    var_data[h_idx, :, :] = to_np(var_3d)
                    
                # For 2D variables, surface is the same as the variable
                if include_surface and surface_value is None:
                    surface_value = to_np(var_3d)
            
            # Return results
            result = {
                'data': var_data,
                'attrs': var_attrs,
                'surface': surface_value
            }
            
            return (var_name, t_idx, result)
                
    except Exception as e:
        print(f"Error processing variable {var_name} at time {t_idx}: {e}")
        return (var_name, t_idx, None)


def get_memory_usage():
    """
    Get current memory usage in MB.
    
    Returns:
    --------
    float:
        Current memory usage in MB
    """
    process = psutil.Process(os.getpid())
    memory_info = process.memory_info()
    return memory_info.rss / 1024 / 1024  # Convert to MB


def adaptive_chunk_size(n_times, n_variables, total_memory_limit_gb=0.8):
    """
    Calculate an adaptive chunk size based on available system memory.
    
    Parameters:
    -----------
    n_times : int
        Number of time steps to process
    n_variables : int
        Number of variables to process
    total_memory_limit_gb : float
        Maximum fraction of system memory to use
        
    Returns:
    --------
    int:
        Chunk size for processing batches
    """
    # Get system memory
    total_memory_gb = psutil.virtual_memory().total / (1024 ** 3)
    
    # Limit to a percentage of available memory
    memory_limit_gb = total_memory_gb * total_memory_limit_gb
    
    # Estimate memory for each task
    # This is a rough approximation based on typical WRF file sizes
    estimated_task_memory_mb = 100  # MB per task
    
    # Calculate how many tasks we could potentially run given our memory limit
    max_tasks = int((memory_limit_gb * 1024) / estimated_task_memory_mb)
    
    # Calculate chunk size, with some safety factor
    chunk_size = max(1, min(n_times, max_tasks // (n_variables * 2)))
    
    return chunk_size


def process_timestep_chunks(wrfout_file, variables, heights, time_chunks, include_surface=True, max_workers=None):
    """
    Process chunks of time steps for efficient parallelization.
    
    Parameters:
    -----------
    wrfout_file : str
        Path to WRF output file
    variables : list
        List of variable names to extract
    heights : list
        List of heights in meters to extract variables at
    time_chunks : list
        List of lists of time indices to process in chunks
    include_surface : bool
        Whether to include surface level values
    max_workers : int
        Maximum number of worker processes to use
        
    Returns:
    --------
    dict:
        Dictionary of results with structure {var_name: {time_idx: result_dict}}
    """
    # Get dimensions once to avoid opening the file repeatedly
    with Dataset(wrfout_file, 'r') as ncfile:
        lats, lons = getvar(ncfile, "lat"), getvar(ncfile, "lon")
        shape = (lats.shape[0], lats.shape[1])
    
    # Results storage
    all_results = {var: {} for var in variables}
    
    # Set up progress reporting
    total_tasks = sum(len(chunk) for chunk in time_chunks) * len(variables)
    completed_tasks = 0
    start_time = time.time()
    
    # Process each chunk of time steps
    for chunk_idx, time_chunk in enumerate(time_chunks):
        print(f"Processing chunk {chunk_idx+1}/{len(time_chunks)} ({len(time_chunk)} time steps)")
        
        # Create task arguments
        tasks = []
        for t_idx in time_chunk:
            for var_name in variables:
                tasks.append((wrfout_file, var_name, t_idx, heights, include_surface, shape))
        
        # Process tasks in parallel
        with concurrent.futures.ProcessPoolExecutor(max_workers=max_workers) as executor:
            # Submit all tasks
            future_to_task = {executor.submit(process_variable_at_time, task): task for task in tasks}
            
            # Process results as they complete
            for future in concurrent.futures.as_completed(future_to_task):
                try:
                    var_name, t_idx, result = future.result()
                    if result is not None:
                        all_results[var_name][t_idx] = result
                    
                    # Update progress
                    completed_tasks += 1
                    if completed_tasks % max(1, total_tasks // 100) == 0:
                        elapsed = time.time() - start_time
                        progress = completed_tasks / total_tasks * 100
                        est_total = elapsed / (completed_tasks / total_tasks)
                        remaining = est_total - elapsed
                        memory_usage_mb = get_memory_usage()
                        
                        print(f"Progress: {progress:.1f}% ({completed_tasks}/{total_tasks}), "
                              f"Memory: {memory_usage_mb:.1f} MB, "
                              f"Est. remaining: {remaining:.1f}s")
                        
                except Exception as e:
                    print(f"Error in task processing: {e}")
        
        # Explicitly trigger garbage collection after each chunk
        import gc
        gc.collect()
    
    return all_results


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
    print(f"Using up to {n_processes} processes for parallel extraction")
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

        # Create output file with dimensions
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

        # Determine optimal chunk size based on memory constraints
        chunk_size = adaptive_chunk_size(n_times, len(variables))
        print(f"Processing in chunks of {chunk_size} time steps")
        
        # Create time chunks
        time_indices = list(range(n_times))
        time_chunks = [time_indices[i:i+chunk_size] for i in range(0, n_times, chunk_size)]
        
        # Process all chunks
        all_results = process_timestep_chunks(
            wrfout_file, 
            variables, 
            heights, 
            time_chunks,
            include_surface,
            max_workers=n_processes
        )
        
        # Now write the results to the output file
        with Dataset(output_file, 'a') as outfile:
            # Determine all found variables
            found_variables = [var for var in variables if all_results[var]]
            
            if not found_variables:
                print("Warning: No variables were successfully processed!")
                return
            
            print(f"Writing {len(found_variables)} variables to output file")
            
            # Create netCDF variables and write data incrementally
            var_dims = ('time', 'height', 'south_north', 'west_east')
            surface_dims = ('time', 'south_north', 'west_east')
            
            # Create all variables first
            nc_vars = {}
            nc_surf_vars = {}
            
            for var_name in found_variables:
                # Get attributes from the first available time step
                var_attrs = None
                for t_result in all_results[var_name].values():
                    if t_result and 'attrs' in t_result:
                        var_attrs = t_result['attrs']
                        break
                
                if var_attrs is None:
                    print(f"Warning: Could not find attributes for {var_name}, skipping")
                    continue
                
                print(f"Creating output variable: {var_name}")
                
                # Create main variable
                nc_var = outfile.createVariable(var_name, 'f8', var_dims,
                                              zlib=True, complevel=1)
                
                # Copy attributes
                for attr_name, attr_value in var_attrs.items():
                    try:
                        setattr(nc_var, attr_name, attr_value)
                    except Exception as e:
                        print(f"Warning: Couldn't set attribute {attr_name} for {var_name}: {e}")
                
                nc_vars[var_name] = nc_var
                
                # Create surface variable if needed
                if include_surface:
                    surf_var_name = f"{var_name}_surface"
                    surf_var = outfile.createVariable(surf_var_name, 'f8', surface_dims,
                                                     zlib=True, complevel=1)
                    
                    # Copy attributes
                    for attr_name, attr_value in var_attrs.items():
                        try:
                            setattr(surf_var, attr_name, attr_value)
                        except Exception as e:
                            print(f"Warning: Couldn't set attribute {attr_name} for {surf_var_name}: {e}")
                    
                    # Add surface-specific attributes
                    surf_var.description = f"Surface level values for {var_name}"
                    
                    nc_surf_vars[var_name] = surf_var
            
            # Write data for each time step
            for t_idx in range(n_times):
                for var_name in found_variables:
                    if t_idx in all_results[var_name]:
                        var_result = all_results[var_name][t_idx]
                        if var_result:
                            # Write main variable data
                            nc_vars[var_name][t_idx] = var_result['data']
                            
                            # Write surface data if available
                            if include_surface and var_name in nc_surf_vars and var_result['surface'] is not None:
                                nc_surf_vars[var_name][t_idx] = var_result['surface']
            
            # Release memory as we go
            all_results = None

        elapsed_time = time.time() - start_time
        print(f"Extraction completed in {elapsed_time:.2f} seconds")
        print(f"Output saved to: {output_file}")

    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


def process_file_wrapper(args):
    """
    Wrapper function for processing a single file in parallel.
    
    Parameters:
    -----------
    args : tuple
        (i, total_files, wrfout_file, variables, heights, output_file, n_processes, include_surface)
    
    Returns:
    --------
    tuple:
        (wrfout_file, output_file, success)
    """
    i, total_files, wrfout_file, variables, heights, output_file, n_processes, include_surface = args
    
    try:
        print(f"\nProcessing file {i+1}/{total_files}: {wrfout_file}")
        extract_variables_at_heights(
            wrfout_file, 
            variables, 
            heights, 
            output_file, 
            n_processes, 
            include_surface
        )
        return (wrfout_file, output_file, True)
    except Exception as e:
        print(f"Error processing file {wrfout_file}: {e}")
        return (wrfout_file, output_file, False)


def process_all_wrfout_files(config):
    """
    Process all wrfout files based on the provided configuration.
    
    Parameters:
    -----------
    config : dict
        Configuration dictionary with all the processing parameters
    
    Returns:
    --------
    None
    """
    input_folder = config['input']['folder']
    file_pattern = config['input']['pattern']
    output_folder = config['output']['folder']
    output_prefix = config['output']['prefix']
    variables = config['variables']
    heights = config['heights']
    include_surface = config['options']['include_surface']
    n_processes = config['options']['processes']
    
    # New option for parallel file processing
    process_files_parallel = config['options'].get('process_files_parallel', False)
    max_parallel_files = config['options'].get('max_parallel_files', 1)
    
    # Ensure output folder exists
    os.makedirs(output_folder, exist_ok=True)
    
    # Get all matching input files
    file_pattern_path = os.path.join(input_folder, file_pattern)
    wrfout_files = sorted(glob.glob(file_pattern_path))
    
    if not wrfout_files:
        print(f"Error: No files found matching pattern '{file_pattern}' in folder '{input_folder}'")
        return
    
    print(f"Found {len(wrfout_files)} files to process")
    
    # Prepare file processing arguments
    file_args = []
    for i, wrfout_file in enumerate(wrfout_files):
        # Generate output filename
        base_name = os.path.basename(wrfout_file).replace('.nc', '').replace('wrfout_', '')
        output_file = os.path.join(output_folder, f'{output_prefix}{base_name}.nc')
        
        # Add to args list
        file_args.append((
            i, 
            len(wrfout_files), 
            wrfout_file, 
            variables, 
            heights, 
            output_file, 
            n_processes, 
            include_surface
        ))
    
    # Process files
    if process_files_parallel and max_parallel_files > 1:
        # Process multiple files in parallel
        print(f"Processing up to {max_parallel_files} files in parallel")
        
        successful_files = 0
        failed_files = 0
        
        with concurrent.futures.ProcessPoolExecutor(max_workers=max_parallel_files) as executor:
            for wrfout_file, output_file, success in executor.map(process_file_wrapper, file_args):
                if success:
                    successful_files += 1
                    print(f"Successfully processed: {wrfout_file} -> {output_file}")
                else:
                    failed_files += 1
                    print(f"Failed to process: {wrfout_file}")
        
        print(f"Processing complete: {successful_files} successful, {failed_files} failed")
    else:
        # Process files sequentially
        for args in file_args:
            process_file_wrapper(args)


def load_config(config_file):
    """
    Load configuration from a YAML file.
    
    Parameters:
    -----------
    config_file : str
        Path to the configuration file
        
    Returns:
    --------
    dict:
        Configuration dictionary
    """
    try:
        with open(config_file, 'r') as file:
            config = yaml.safe_load(file)
        
        # Validate required fields
        required_fields = [
            ('input', 'folder'), 
            ('input', 'pattern'), 
            ('output', 'folder'),
            ('variables',), 
            ('heights',)
        ]
        
        for field in required_fields:
            current = config
            for key in field:
                if key not in current:
                    raise ValueError(f"Missing required configuration field: {'.'.join(field)}")
                current = current[key]
        
        # Set defaults for optional fields
        if 'prefix' not in config['output']:
            config['output']['prefix'] = 'extracted_'
            
        if 'options' not in config:
            config['options'] = {}
            
        if 'include_surface' not in config['options']:
            config['options']['include_surface'] = True
            
        if 'processes' not in config['options']:
            config['options']['processes'] = None
            
        if 'process_files_parallel' not in config['options']:
            config['options']['process_files_parallel'] = False
            
        if 'max_parallel_files' not in config['options']:
            config['options']['max_parallel_files'] = 1
            
        return config
        
    except Exception as e:
        print(f"Error loading configuration file: {e}")
        sys.exit(1)


def main():
    """Main function to parse arguments and call extraction function."""
    import argparse

    parser = argparse.ArgumentParser(description='Extract WRF variables at specific heights and surface level')
    
    # Config file option
    parser.add_argument('--config', '-c', help='Path to YAML configuration file')
    
    # Individual options (for backward compatibility and direct usage)
    parser.add_argument('--wrfout-file', help='Path to single WRF output file')
    parser.add_argument('--input-folder', help='Folder containing WRF output files')
    parser.add_argument('--file-pattern', default='wrfout_d01_*', help='Pattern for matching WRF files')
    parser.add_argument('--output-folder', help='Folder for output files')
    parser.add_argument('--output-prefix', default='extracted_', help='Prefix for output files')
    parser.add_argument('--vars', '-v', nargs='+', help='Variables to extract (e.g., ua va tc rh)')
    parser.add_argument('--heights', '-z', nargs='+', type=float, help='Heights in meters to extract variables at')
    parser.add_argument('--processes', '-p', type=int, default=None, help='Number of processes to use (default: CPU count - 1)')
    parser.add_argument('--no-surface', action='store_true', help='Skip extraction of surface (ground level) data')
    parser.add_argument('--parallel-files', action='store_true', help='Process multiple files in parallel')
    parser.add_argument('--max-parallel-files', type=int, default=1, help='Maximum number of files to process in parallel')

    args = parser.parse_args()
    
    # Check if config file is provided
    if args.config:
        config = load_config(args.config)
        process_all_wrfout_files(config)
        return 0
    
    # Backward compatibility mode - process a single file
    if args.wrfout_file:
        if not args.vars or not args.heights:
            parser.error("When using --wrfout-file, you must also specify --vars and --heights")
            
        # Set default output name if not provided
        output_file = None
        if args.output_folder:
            base_name = os.path.basename(args.wrfout_file).replace('.nc', '').replace('wrfout_', '')
            output_file = os.path.join(args.output_folder, f'{args.output_prefix or "extracted_"}{base_name}.nc')
        else:
            base_dir = os.path.dirname(args.wrfout_file)
            base_name = os.path.basename(args.wrfout_file).replace('.nc', '').replace('wrfout_', '')
            output_file = os.path.join(base_dir, f'extracted_{base_name}.nc')
            
        # Print summary of extraction parameters
        print("\nWRF Variable Extraction")
        print("======================")
        print(f"Input file:  {args.wrfout_file}")
        print(f"Variables:   {', '.join(args.vars)}")
        print(f"Heights (m): {', '.join(map(str, args.heights))}")
        print(f"Include surface: {not args.no_surface}")
        print(f"Output file: {output_file}")
        print(f"Processes:   {args.processes or 'auto'}")
        print("======================\n")
        
        # Perform the extraction
        extract_variables_at_heights(
            args.wrfout_file,
            args.vars,
            args.heights,
            output_file,
            args.processes,
            include_surface=not args.no_surface
        )
        return 0
        
    # Process multiple files based on command line arguments
    if args.input_folder:
        if not args.vars or not args.heights or not args.output_folder:
            parser.error("When using --input-folder, you must also specify --vars, --heights, and --output-folder")
            
        # Create a config dictionary from command line arguments
        config = {
            'input': {
                'folder': args.input_folder,
                'pattern': args.file_pattern
            },
            'output': {
                'folder': args.output_folder,
                'prefix': args.output_prefix or 'extracted_'
            },
            'variables': args.vars,
            'heights': args.heights,
            'options': {
                'include_surface': not args.no_surface,
                'processes': args.processes,
                'process_files_parallel': args.parallel_files,
                'max_parallel_files': args.max_parallel_files
            }
        }
        
        # Process all files
        process_all_wrfout_files(config)
        return 0
        
    # If no action specified, show help
    parser.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
