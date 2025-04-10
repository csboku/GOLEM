"""
GOLEM Refactored Python Library

This module provides functions for environmental data analysis and visualization,
organized into logical sections using standard module-level functions.

Sections:
- Data Processing: Functions for data manipulation and preprocessing
- Visualization: Plotting and visualization tools
- Statistics: Statistical analysis functions
- Spatial: Geospatial operations

Author: GOLEM Team (Refactored Version)
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.colors import LinearSegmentedColormap
import xarray as xr
from typing import Dict, List, Tuple, Union, Callable, Optional, Any

#####################################
# Data Processing Functions
#####################################

def remove_missing(data: np.ndarray) -> np.ndarray:
    """
    Remove missing values (NaN) from a NumPy array.

    Args:
        data: Input array with possible NaN values.

    Returns:
        NumPy array with NaN values removed.
    """
    return data[~np.isnan(data)]

def calculate_exceedances(data: np.ndarray, threshold: float = 120.0) -> np.ndarray:
    """
    Identify values in an array that exceed a given threshold.

    Args:
        data: Input data array (NumPy array).
        threshold: The threshold value for exceedance calculation. Defaults to 120.0.

    Returns:
        A binary NumPy array where 1 indicates an exceedance (value >= threshold)
        and 0 indicates no exceedance.
    """
    return np.where(data >= threshold, 1, 0)

def read_netcdf(file_path: str, variables: List[str] = None) -> Dict[str, np.ndarray]:
    """
    Read specified variables from a NetCDF file.

    Args:
        file_path: Path to the NetCDF file.
        variables: Optional list of variable names to extract. If None, extracts all data variables.

    Returns:
        A dictionary where keys are variable names and values are the corresponding
        NumPy arrays. Returns an empty dictionary if an error occurs.
    """
    try:
        with xr.open_dataset(file_path) as ds:
            result = {}
            var_list = variables if variables is not None else list(ds.data_vars)

            for var in var_list:
                if var in ds:
                    result[var] = ds[var].values
                else:
                     print(f"Warning: Variable '{var}' not found in {file_path}")

            return result
    except FileNotFoundError:
        print(f"Error: NetCDF file not found at {file_path}")
        return {}
    except Exception as e:
        print(f"Error reading NetCDF file '{file_path}': {e}")
        return {}

def filter_by_altitude(data: pd.DataFrame, alt_col: str = 'altitude', max_alt: float = 1500) -> pd.DataFrame:
    """
    Filter a Pandas DataFrame based on a maximum altitude threshold.

    Args:
        data: Input Pandas DataFrame.
        alt_col: Name of the column containing altitude data. Defaults to 'altitude'.
        max_alt: The maximum altitude threshold (exclusive). Defaults to 1500.

    Returns:
        A filtered Pandas DataFrame containing only rows where the altitude
        is less than max_alt.

    Raises:
        ValueError: If the specified altitude column does not exist in the DataFrame.
    """
    if alt_col not in data.columns:
        raise ValueError(f"Altitude column '{alt_col}' not found in DataFrame columns: {data.columns}")

    return data[data[alt_col] < max_alt].copy() # Return a copy to avoid SettingWithCopyWarning

def filter_by_season(data: pd.DataFrame, date_col: str = 'date', season: str = 'JJA') -> pd.DataFrame:
    """
    Filter a Pandas DataFrame to include only data from a specific meteorological season.

    Args:
        data: Input Pandas DataFrame.
        date_col: Name of the column containing date/datetime objects. Defaults to 'date'.
        season: The meteorological season code ('DJF', 'MAM', 'JJA', 'SON'). Defaults to 'JJA'.

    Returns:
        A filtered Pandas DataFrame containing only rows corresponding to the specified season.

    Raises:
        ValueError: If the specified date column does not exist or if the season code is invalid.
        TypeError: If the date column cannot be converted to DatetimeIndex.
    """
    if date_col not in data.columns:
        raise ValueError(f"Date column '{date_col}' not found in DataFrame columns: {data.columns}")

    season_map = {
        'DJF': [12, 1, 2], # December, January, February
        'MAM': [3, 4, 5],  # March, April, May
        'JJA': [6, 7, 8],  # June, July, August
        'SON': [9, 10, 11] # September, October, November
    }

    if season not in season_map:
        raise ValueError(f"Unknown season code: '{season}'. Valid codes are 'DJF', 'MAM', 'JJA', 'SON'.")

    try:
        # Ensure the date column is in datetime format
        datetime_index = pd.DatetimeIndex(data[date_col])
    except Exception as e:
        raise TypeError(f"Could not convert column '{date_col}' to DatetimeIndex. Error: {e}")

    # Extract month numbers and filter
    months = datetime_index.month
    filtered_data = data[months.isin(season_map[season])]
    return filtered_data.copy() # Return a copy

def aggregate_by_season(data: pd.DataFrame, date_col: str = 'date', value_col: str = 'value') -> Dict[str, pd.DataFrame]:
    """
    Aggregate data in a DataFrame by meteorological season.

    Note: This function currently groups the data but doesn't perform aggregation (like mean, sum).
          It returns subsets of the DataFrame for each season.

    Args:
        data: Input Pandas DataFrame.
        date_col: Name of the column containing date/datetime objects. Defaults to 'date'.
        value_col: Name of the column containing the values to potentially aggregate (currently unused for aggregation). Defaults to 'value'.

    Returns:
        A dictionary where keys are season codes ('DJF', 'MAM', 'JJA', 'SON')
        and values are Pandas DataFrames containing the data for that season.

    Raises:
        ValueError: If the specified date or value columns do not exist.
        TypeError: If the date column cannot be converted to DatetimeIndex.
    """
    if date_col not in data.columns:
        raise ValueError(f"Date column '{date_col}' not found in DataFrame columns: {data.columns}")
    if value_col not in data.columns:
         raise ValueError(f"Value column '{value_col}' not found in DataFrame columns: {data.columns}")

    season_map = {
        'DJF': [12, 1, 2],
        'MAM': [3, 4, 5],
        'JJA': [6, 7, 8],
        'SON': [9, 10, 11]
    }

    result = {}
    try:
        # Ensure the date column is in datetime format
        datetime_index = pd.DatetimeIndex(data[date_col])
    except Exception as e:
        raise TypeError(f"Could not convert column '{date_col}' to DatetimeIndex. Error: {e}")

    # Extract month numbers
    months = datetime_index.month

    # Create subsets for each season
    for season, season_months in season_map.items():
        season_data = data[months.isin(season_months)]
        if not season_data.empty:
            result[season] = season_data.copy() # Store a copy

    return result


#####################################
# Visualization Functions
#####################################

def setup_figure(figsize: Tuple[float, float] = (12, 8), style: str = 'seaborn-v0_8-whitegrid') -> Tuple[plt.Figure, plt.Axes]:
    """
    Set up a basic Matplotlib figure and axes object with a specified style.

    Args:
        figsize: Tuple specifying figure size (width, height) in inches. Defaults to (12, 8).
        style: Matplotlib style sheet name. Defaults to 'seaborn-v0_8-whitegrid'.

    Returns:
        A tuple containing the Matplotlib Figure and Axes objects.
    """
    try:
        plt.style.use(style)
    except OSError:
        print(f"Warning: Style '{style}' not found. Using default style.")
    fig, ax = plt.subplots(figsize=figsize)
    return fig, ax

def setup_multi_panel(nrows: int = 2, ncols: int = 2, figsize: Tuple[float, float] = (12, 8),
                      height_ratios: Optional[List[float]] = None, width_ratios: Optional[List[float]] = None,
                      style: str = 'seaborn-v0_8-whitegrid') -> Tuple[plt.Figure, List[plt.Axes]]:
    """
    Set up a multi-panel Matplotlib figure using GridSpec.

    Args:
        nrows: Number of rows in the grid. Defaults to 2.
        ncols: Number of columns in the grid. Defaults to 2.
        figsize: Tuple specifying the overall figure size (width, height) in inches. Defaults to (12, 8).
        height_ratios: Optional list of relative heights for each row.
        width_ratios: Optional list of relative widths for each column.
        style: Matplotlib style sheet name. Defaults to 'seaborn-v0_8-whitegrid'.

    Returns:
        A tuple containing the Matplotlib Figure object and a list of Axes objects
        corresponding to each panel in the grid (ordered row-wise).
    """
    try:
        plt.style.use(style)
    except OSError:
        print(f"Warning: Style '{style}' not found. Using default style.")

    fig = plt.figure(figsize=figsize)

    # Prepare GridSpec keyword arguments
    grid_kw = {}
    if height_ratios is not None:
        if len(height_ratios) != nrows:
             raise ValueError(f"Length of height_ratios ({len(height_ratios)}) must match nrows ({nrows})")
        grid_kw['height_ratios'] = height_ratios
    if width_ratios is not None:
        if len(width_ratios) != ncols:
             raise ValueError(f"Length of width_ratios ({len(width_ratios)}) must match ncols ({ncols})")
        grid_kw['width_ratios'] = width_ratios

    # Create GridSpec
    gs = gridspec.GridSpec(nrows, ncols, figure=fig, **grid_kw)

    # Create subplots in the grid
    axes = [fig.add_subplot(gs[i, j]) for i in range(nrows) for j in range(ncols)]

    return fig, axes

def create_boxplot_comparison(ax: plt.Axes, data_dict: Dict[str, List[List[float]]], labels: List[str],
                            positions: np.ndarray, colors: List[str], width: float = 0.15,
                            title: str = '', ylabel: str = '') -> None:
    """
    Create a grouped boxplot on a given Matplotlib Axes for comparing distributions.

    Args:
        ax: The Matplotlib Axes object to plot on.
        data_dict: A dictionary where keys are scenario/group names (str) and values are lists
                   of data lists. Each inner list corresponds to a category on the x-axis.
                   Example: {'Model A': [[1,2,3], [4,5,6]], 'Model B': [[2,3,4], [5,6,7]]}
                   for two models and two categories.
        labels: List of strings for the x-axis category labels.
        positions: NumPy array specifying the center positions for each category group on the x-axis.
        colors: List of color codes (str) for each scenario/group in data_dict.
        width: The width of each individual boxplot. Defaults to 0.15.
        title: Optional title for the plot.
        ylabel: Optional label for the y-axis.

    Raises:
        ValueError: If the number of colors doesn't match the number of scenarios,
                    or if data dimensions are inconsistent.
    """
    num_scenarios = len(data_dict)
    num_categories = len(labels)

    if len(colors) < num_scenarios:
         raise ValueError(f"Number of colors ({len(colors)}) is less than the number of scenarios ({num_scenarios}).")
    if len(positions) != num_categories:
        raise ValueError(f"Length of positions ({len(positions)}) must match the number of labels ({num_categories}).")

    # Calculate the total width needed for each group of boxes
    total_group_width = num_scenarios * width
    # Calculate the starting offset for the first box in each group
    start_offset = -total_group_width / 2 + width / 2

    offset = start_offset
    for i, (scenario, scenario_data) in enumerate(data_dict.items()):
        if len(scenario_data) != num_categories:
             raise ValueError(f"Data for scenario '{scenario}' has {len(scenario_data)} categories, expected {num_categories}.")

        # Prepare data for boxplot: remove NaNs from each category's list
        plot_data = [remove_missing(np.array(cat_data)) for cat_data in scenario_data]

        bp = ax.boxplot(plot_data,
                        positions=positions + offset,
                        widths=width,
                        patch_artist=True, # Needed to fill boxes with color
                        medianprops=dict(color='black'), # Style median line
                        flierprops=dict(marker='o', markersize=4, markerfacecolor='grey', markeredgecolor='none'), # Style outliers
                        showfliers=True) # Show outliers

        # Set box colors
        for patch in bp['boxes']:
            patch.set_facecolor(colors[i])
            patch.set_edgecolor('black') # Add edge color for clarity
            patch.set_linewidth(0.5)

        # Add space for the next box in the group
        offset += width

    # Configure axes
    ax.set_title(title, pad=10) # Add padding to title
    ax.set_ylabel(ylabel)
    ax.set_xticks(positions)
    ax.set_xticklabels(labels)
    ax.tick_params(axis='x', rotation=0) # Ensure labels are horizontal unless needed otherwise

def create_bar_comparison(ax: plt.Axes, data_dict: Dict[str, List[float]], labels: List[str],
                        colors: List[str], width: float = 0.15, title: str = '',
                        ylabel: str = '') -> None:
    """
    Create a grouped bar chart on a given Matplotlib Axes for comparing values.

    Args:
        ax: The Matplotlib Axes object to plot on.
        data_dict: A dictionary where keys are scenario/group names (str) and values are lists
                   of numerical values. Each list corresponds to the categories on the x-axis.
                   Example: {'Model A': [10, 20], 'Model B': [12, 18]} for two models and two categories.
        labels: List of strings for the x-axis category labels.
        colors: List of color codes (str) for each scenario/group in data_dict.
        width: The width of each individual bar. Defaults to 0.15.
        title: Optional title for the plot.
        ylabel: Optional label for the y-axis.

    Raises:
        ValueError: If the number of colors doesn't match the number of scenarios,
                    or if data dimensions are inconsistent.
    """
    num_scenarios = len(data_dict)
    num_categories = len(labels)

    if len(colors) < num_scenarios:
         raise ValueError(f"Number of colors ({len(colors)}) is less than the number of scenarios ({num_scenarios}).")

    x = np.arange(num_categories) # Base positions for categories

    # Calculate the total width needed for each group of bars
    total_group_width = num_scenarios * width
    # Calculate the starting offset for the first bar in each group
    start_offset = -total_group_width / 2 + width / 2

    offset = start_offset
    for i, (scenario, scenario_values) in enumerate(data_dict.items()):
        if len(scenario_values) != num_categories:
             raise ValueError(f"Data for scenario '{scenario}' has {len(scenario_values)} categories, expected {num_categories}.")

        ax.bar(x + offset, scenario_values, width, label=scenario, color=colors[i], edgecolor='black', linewidth=0.5)
        offset += width

    # Configure axes
    ax.set_title(title, pad=10)
    ax.set_ylabel(ylabel)
    ax.set_xticks(x) # Set tick positions to the center of the groups
    ax.set_xticklabels(labels)
    ax.tick_params(axis='x', rotation=0)

def plot_density_comparison(data_dict: Dict[str, np.ndarray], figsize: Tuple[float, float] = (10, 6),
                          title: str = 'Density Comparison', xlabel: str = 'Value',
                          ylabel: str = 'Density', colors: Optional[List[str]] = None,
                          bins: int = 30, alpha: float = 0.5) -> Tuple[plt.Figure, plt.Axes]:
    """
    Create overlaid density plots (histograms) for comparing multiple datasets.

    Args:
        data_dict: Dictionary where keys are dataset names (str) and values are NumPy arrays of data.
        figsize: Tuple specifying figure size (width, height) in inches. Defaults to (10, 6).
        title: Plot title. Defaults to 'Density Comparison'.
        xlabel: X-axis label. Defaults to 'Value'.
        ylabel: Y-axis label. Defaults to 'Density'.
        colors: Optional list of color codes (str) for each dataset. If None, uses default colors.
        bins: Number of bins for the histogram. Defaults to 30.
        alpha: Transparency level for the histograms. Defaults to 0.5.

    Returns:
        A tuple containing the Matplotlib Figure and Axes objects.
    """
    fig, ax = setup_figure(figsize=figsize) # Use setup_figure for consistency

    num_datasets = len(data_dict)
    if colors is None:
        # Generate default colors if none provided
        prop_cycle = plt.rcParams['axes.prop_cycle']
        default_colors = prop_cycle.by_key()['color']
        plot_colors = [default_colors[i % len(default_colors)] for i in range(num_datasets)]
    elif len(colors) < num_datasets:
        raise ValueError(f"Number of colors ({len(colors)}) is less than the number of datasets ({num_datasets}).")
    else:
        plot_colors = colors

    for i, (name, data) in enumerate(data_dict.items()):
        # Remove missing values before plotting
        clean_data = remove_missing(data)
        if len(clean_data) > 0:
            ax.hist(clean_data, bins=bins, density=True, alpha=alpha, color=plot_colors[i], label=name, edgecolor='black', linewidth=0.5)
        else:
            print(f"Warning: Dataset '{name}' is empty or contains only NaNs after cleaning. Skipping.")

    ax.set_title(title)
    ax.set_xlabel(xlabel)
    ax.set_ylabel(ylabel)
    if num_datasets > 0: # Only add legend if there's data
        ax.legend()
    ax.grid(True, linestyle='--', alpha=0.6) # Add grid for better readability

    return fig, ax

def save_figure(fig: plt.Figure, filename: str, dpi: int = 300, bbox_inches: str = 'tight',
              formats: List[str] = ['png', 'pdf']) -> None:
    """
    Save a Matplotlib figure in one or more specified formats.

    Args:
        fig: The Matplotlib Figure object to save.
        filename: The base filename (without extension) for the saved files.
        dpi: Resolution (dots per inch) for raster formats (like PNG). Defaults to 300.
        bbox_inches: Bounding box specification ('tight' removes whitespace). Defaults to 'tight'.
        formats: A list of file format extensions (e.g., 'png', 'pdf', 'svg'). Defaults to ['png', 'pdf'].
    """
    for fmt in formats:
        try:
            # Use specific dpi only for raster formats, pdf handles resolution differently
            save_dpi = dpi if fmt.lower() in ['png', 'jpg', 'jpeg', 'tiff'] else None
            full_filename = f"{filename}.{fmt}"
            fig.savefig(full_filename, dpi=save_dpi, bbox_inches=bbox_inches)
            print(f"Figure saved as {full_filename}")
        except Exception as e:
            print(f"Error saving figure to {filename}.{fmt}: {e}")


#####################################
# Statistics Functions
#####################################

def calc_statistical_metrics(obs: np.ndarray, model: np.ndarray) -> Dict[str, Union[float, int]]:
    """
    Calculate common statistical metrics between two datasets (e.g., observations and model).

    Calculates Bias, RMSE (Root Mean Square Error), MAE (Mean Absolute Error),
    Pearson Correlation Coefficient, and the number of valid data points used.
    Handles NaN values by pairwise removal.

    Args:
        obs: NumPy array of observation data.
        model: NumPy array of model data. Must have the same shape as obs.

    Returns:
        A dictionary containing the calculated metrics: 'bias', 'rmse', 'mae',
        'correlation', 'n_points'. Returns NaNs for metrics if no valid
        overlapping data points exist.

    Raises:
        ValueError: If input arrays have different shapes.
    """
    if obs.shape != model.shape:
        raise ValueError(f"Input arrays must have the same shape. Got {obs.shape} and {model.shape}.")

    # Identify valid pairs (non-NaN in both arrays)
    valid_mask = ~np.isnan(obs) & ~np.isnan(model)
    clean_obs = obs[valid_mask]
    clean_model = model[valid_mask]
    n_points = len(clean_obs)

    if n_points == 0:
        # Return NaNs if no valid pairs
        return {
            'bias': np.nan,
            'rmse': np.nan,
            'mae': np.nan,
            'correlation': np.nan,
            'n_points': 0
        }
    elif n_points == 1:
         # Correlation is undefined for a single point
         bias = np.mean(clean_model - clean_obs) # Same as the difference
         rmse = np.sqrt(np.mean((clean_model - clean_obs)**2)) # Same as abs difference
         mae = np.mean(np.abs(clean_model - clean_obs)) # Same as abs difference
         corr = np.nan
         return {
            'bias': bias,
            'rmse': rmse,
            'mae': mae,
            'correlation': corr,
            'n_points': n_points
         }


    # Calculate metrics
    diff = clean_model - clean_obs
    bias = np.mean(diff)
    rmse = np.sqrt(np.mean(diff**2))
    mae = np.mean(np.abs(diff))

    # Calculate correlation using numpy's corrcoef
    # Need at least 2 points for correlation
    corr_matrix = np.corrcoef(clean_obs, clean_model)
    correlation = corr_matrix[0, 1]

    return {
        'bias': bias,
        'rmse': rmse,
        'mae': mae,
        'correlation': correlation,
        'n_points': n_points
    }

def compare_models(ref_data: np.ndarray, model_dict: Dict[str, np.ndarray]) -> pd.DataFrame:
    """
    Compare multiple model datasets against a reference dataset using statistical metrics.

    Args:
        ref_data: NumPy array of reference data (e.g., observations).
        model_dict: Dictionary where keys are model names (str) and values are
                    NumPy arrays of model data. Each model array must have the
                    same shape as ref_data.

    Returns:
        A Pandas DataFrame where each row represents a model and columns contain
        the statistical metrics ('bias', 'rmse', 'mae', 'correlation', 'n_points')
        comparing that model to the reference data. Includes a 'model' column
        with the model names.

    Raises:
        ValueError: If any model array shape does not match the reference data shape.
    """
    results = []

    for model_name, model_data in model_dict.items():
        try:
            metrics = calc_statistical_metrics(ref_data, model_data)
            metrics['model'] = model_name # Add model name to the results dict
            results.append(metrics)
        except ValueError as e:
            print(f"Skipping model '{model_name}' due to error: {e}")
        except Exception as e:
             print(f"An unexpected error occurred while processing model '{model_name}': {e}")


    # Convert list of dictionaries to DataFrame
    if not results:
        # Return empty DataFrame with expected columns if no models were processed
        return pd.DataFrame(columns=['model', 'bias', 'rmse', 'mae', 'correlation', 'n_points'])

    return pd.DataFrame(results)[['model', 'bias', 'rmse', 'mae', 'correlation', 'n_points']] # Ensure column order

def calc_exceedance_stats(data_dict: Dict[str, np.ndarray], threshold: float = 120,
                        by_season: bool = False, dates: Optional[pd.DatetimeIndex] = None) -> Dict[str, Union[int, Dict[str, int]]]:
    """
    Calculate exceedance counts for multiple datasets, optionally grouped by season.

    Args:
        data_dict: Dictionary where keys are dataset names (str) and values are NumPy arrays of data.
        threshold: The threshold value for determining exceedances. Defaults to 120.
        by_season: If True, calculate exceedance counts for each meteorological season (DJF, MAM, JJA, SON).
                   Requires the 'dates' argument to be provided. Defaults to False.
        dates: A Pandas DatetimeIndex corresponding to the data arrays in data_dict.
               Required if by_season is True. Must have the same length as the data arrays.

    Returns:
        A dictionary where keys are dataset names.
        - If by_season is False, values are the total exceedance counts (int) for each dataset.
        - If by_season is True, values are dictionaries themselves, with season codes ('DJF', 'MAM', 'JJA', 'SON')
          as keys and exceedance counts (int) for that season as values.

    Raises:
        ValueError: If by_season is True but 'dates' is not provided, or if 'dates' length
                    doesn't match data array lengths.
    """
    results = {}

    if by_season:
        if dates is None:
            raise ValueError("Argument 'dates' (Pandas DatetimeIndex) must be provided when 'by_season' is True.")
        # Basic check for length consistency - assumes all data arrays have same length as first one
        first_data_key = next(iter(data_dict))
        if len(dates) != len(data_dict[first_data_key]):
             raise ValueError(f"Length of 'dates' ({len(dates)}) must match the length of data arrays ({len(data_dict[first_data_key])}).")

        season_map = {
            'DJF': [12, 1, 2],
            'MAM': [3, 4, 5],
            'JJA': [6, 7, 8],
            'SON': [9, 10, 11]
        }
        # Pre-calculate season masks for efficiency
        month_numbers = dates.month
        season_masks = {
            season: np.isin(month_numbers, months)
            for season, months in season_map.items()
        }

    for name, data in data_dict.items():
        if by_season and len(data) != len(dates):
             # Check individual array length if checking seasonally
             raise ValueError(f"Length mismatch for dataset '{name}'. Data length {len(data)}, dates length {len(dates)}.")

        # Calculate exceedances for the current dataset
        exceedances = calculate_exceedances(data, threshold) # Returns 0s and 1s

        if not by_season:
            # Sum all exceedances if not grouping by season
            results[name] = int(np.sum(exceedances))
        else:
            # Calculate sum for each season using pre-calculated masks
            season_results = {}
            for season, mask in season_masks.items():
                # Apply mask to exceedance array and sum
                season_results[season] = int(np.sum(exceedances[mask]))
            results[name] = season_results

    return results


#####################################
# Spatial Functions
#####################################

def extract_points(raster_data: np.ndarray, lons: np.ndarray, lats: np.ndarray,
                 points: List[Tuple[float, float]], method: str = 'nearest') -> np.ndarray:
    """
    Extract data values from a raster grid at specified point locations.

    Currently supports only 'nearest' neighbor interpolation.

    Args:
        raster_data: 2D NumPy array representing the raster grid data. Assumes (latitude, longitude) dimensions.
        lons: 1D NumPy array of longitude coordinates corresponding to the columns of raster_data.
              Must be monotonically increasing.
        lats: 1D NumPy array of latitude coordinates corresponding to the rows of raster_data.
              Must be monotonically increasing or decreasing.
        points: A list of tuples, where each tuple is a (longitude, latitude) coordinate pair.
        method: Interpolation method. Currently only 'nearest' is implemented. Defaults to 'nearest'.

    Returns:
        A 1D NumPy array containing the extracted data values for each point.
        Returns np.nan for points outside the raster bounds or if errors occur.

    Raises:
        ValueError: If dimensions mismatch or unsupported method is requested.
    """
    if method != 'nearest':
        raise ValueError(f"Method '{method}' not supported. Currently only 'nearest' is implemented.")
    if raster_data.ndim != 2:
        raise ValueError(f"raster_data must be a 2D array, but got {raster_data.ndim} dimensions.")
    if raster_data.shape[0] != len(lats) or raster_data.shape[1] != len(lons):
        raise ValueError(f"Raster dimensions ({raster_data.shape}) do not match coordinate lengths (lats: {len(lats)}, lons: {len(lons)}).")

    # Check monotonicity of coordinates for reliable index finding
    if not np.all(np.diff(lons) > 0):
        raise ValueError("Longitude coordinates must be monotonically increasing.")
    # Latitude can be increasing or decreasing
    lat_increasing = np.all(np.diff(lats) > 0)
    lat_decreasing = np.all(np.diff(lats) < 0)
    if not (lat_increasing or lat_decreasing):
         raise ValueError("Latitude coordinates must be strictly monotonic (either increasing or decreasing).")


    extracted_values = []

    for lon_point, lat_point in points:
        try:
            # Find the index of the nearest longitude
            # np.searchsorted finds where the element *would be inserted*
            # We adjust to find the truly nearest index
            lon_idx_insert = np.searchsorted(lons, lon_point)
            if lon_idx_insert == 0:
                lon_idx = 0
            elif lon_idx_insert == len(lons):
                lon_idx = len(lons) - 1
            else:
                # Check which neighbor is closer
                if abs(lons[lon_idx_insert] - lon_point) < abs(lons[lon_idx_insert - 1] - lon_point):
                    lon_idx = lon_idx_insert
                else:
                    lon_idx = lon_idx_insert - 1

            # Find the index of the nearest latitude (handle increasing/decreasing)
            lat_idx_insert = np.searchsorted(lats, lat_point) if lat_increasing else np.searchsorted(lats[::-1], lat_point)

            if lat_idx_insert == 0:
                lat_idx_raw = 0
            elif lat_idx_insert == len(lats):
                lat_idx_raw = len(lats) - 1
            else:
                 # Check which neighbor is closer (adjusting for potential reversal)
                 lat_comp1 = lats[lat_idx_insert] if lat_increasing else lats[len(lats) - 1 - lat_idx_insert]
                 lat_comp2 = lats[lat_idx_insert - 1] if lat_increasing else lats[len(lats) - lat_idx_insert] # index before insertion point

                 if abs(lat_comp1 - lat_point) < abs(lat_comp2 - lat_point):
                     lat_idx_raw = lat_idx_insert
                 else:
                     lat_idx_raw = lat_idx_insert - 1

            # Convert index back if latitude was decreasing
            lat_idx = lat_idx_raw if lat_increasing else len(lats) - 1 - lat_idx_raw


            # Check bounds strictly (indices must be valid)
            if 0 <= lat_idx < raster_data.shape[0] and 0 <= lon_idx < raster_data.shape[1]:
                 extracted_values.append(raster_data[lat_idx, lon_idx])
            else:
                 # This case should ideally be caught by the index logic, but as a safeguard
                 print(f"Warning: Point ({lon_point}, {lat_point}) resulted in out-of-bounds indices ({lat_idx}, {lon_idx}). Appending NaN.")
                 extracted_values.append(np.nan)

        except Exception as e:
             print(f"Error processing point ({lon_point}, {lat_point}): {e}. Appending NaN.")
             extracted_values.append(np.nan)


    return np.array(extracted_values)

def raster_difference(raster1: np.ndarray, raster2: np.ndarray) -> np.ndarray:
    """
    Calculate the element-wise difference between two raster grids.

    Args:
        raster1: The first 2D NumPy array (minuend).
        raster2: The second 2D NumPy array (subtrahend). Must have the same shape as raster1.

    Returns:
        A 2D NumPy array representing the difference (raster1 - raster2).

    Raises:
        ValueError: If the input rasters do not have the same shape.
    """
    if raster1.shape != raster2.shape:
        raise ValueError(f"Input rasters must have the same shape. Got {raster1.shape} and {raster2.shape}.")

    return raster1 - raster2
