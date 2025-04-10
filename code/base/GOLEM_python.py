"""
GOLEM Python Library

This module provides functions for environmental data analysis and visualization,
organized in a functional approach.

The library is structured into modules:
- data_processing: Functions for data manipulation and preprocessing
- visualization: Plotting and visualization tools
- statistics: Statistical analysis functions
- spatial: Geospatial operations

Author: GOLEM Team
"""

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
from matplotlib.colors import LinearSegmentedColormap
import xarray as xr
from typing import Dict, List, Tuple, Union, Callable, Optional, Any

#####################################
# Data Processing Module
#####################################

class DataProcessing:
    """Data processing and manipulation functions."""
    
    @staticmethod
    def remove_missing(data: np.ndarray) -> np.ndarray:
        """
        Remove missing values from array.
        
        Args:
            data: Input array with possible NaN values
            
        Returns:
            Array with NaN values removed
        """
        return data[~np.isnan(data)]
    
    @staticmethod
    def calculate_exceedances(data: np.ndarray, threshold: float = 120.0) -> np.ndarray:
        """
        Calculate exceedances over a threshold.
        
        Args:
            data: Input data array
            threshold: Exceedance threshold
            
        Returns:
            Binary array with 1 for values >= threshold, 0 otherwise
        """
        return np.where(data >= threshold, 1, 0)
    
    @staticmethod
    def read_netcdf(file_path: str, variables: List[str] = None) -> Dict[str, np.ndarray]:
        """
        Read data from NetCDF file.
        
        Args:
            file_path: Path to NetCDF file
            variables: List of variable names to extract
            
        Returns:
            Dictionary with variable names as keys and arrays as values
        """
        try:
            ds = xr.open_dataset(file_path)
            result = {}
            
            if variables is None:
                variables = list(ds.data_vars)
                
            for var in variables:
                if var in ds:
                    result[var] = ds[var].values
                    
            ds.close()
            return result
        except Exception as e:
            print(f"Error reading NetCDF file: {e}")
            return {}
    
    @staticmethod
    def filter_by_altitude(data: pd.DataFrame, alt_col: str = 'altitude', max_alt: float = 1500) -> pd.DataFrame:
        """
        Filter dataframe by altitude.
        
        Args:
            data: Input dataframe
            alt_col: Name of altitude column
            max_alt: Maximum altitude threshold
            
        Returns:
            Filtered dataframe
        """
        if alt_col not in data.columns:
            raise ValueError(f"Column {alt_col} not found in dataframe")
        
        return data[data[alt_col] < max_alt]
    
    @staticmethod
    def filter_by_season(data: pd.DataFrame, date_col: str = 'date', season: str = 'JJA') -> pd.DataFrame:
        """
        Filter dataframe by meteorological season.
        
        Args:
            data: Input dataframe
            date_col: Name of date column
            season: Season code (DJF, MAM, JJA, SON)
            
        Returns:
            Filtered dataframe
        """
        if date_col not in data.columns:
            raise ValueError(f"Column {date_col} not found in dataframe")
        
        season_map = {
            'DJF': [12, 1, 2],
            'MAM': [3, 4, 5],
            'JJA': [6, 7, 8],
            'SON': [9, 10, 11]
        }
        
        if season not in season_map:
            raise ValueError(f"Unknown season: {season}. Use DJF, MAM, JJA, or SON.")
        
        # Extract month and filter
        months = pd.DatetimeIndex(data[date_col]).month
        return data[months.isin(season_map[season])]
    
    @staticmethod
    def aggregate_by_season(data: pd.DataFrame, date_col: str = 'date', value_col: str = 'value') -> Dict[str, pd.DataFrame]:
        """
        Aggregate data by season.
        
        Args:
            data: Input dataframe
            date_col: Name of date column
            value_col: Name of value column
            
        Returns:
            Dictionary with season codes as keys and aggregated data as values
        """
        if date_col not in data.columns or value_col not in data.columns:
            raise ValueError(f"Columns {date_col} or {value_col} not found in dataframe")
        
        season_map = {
            'DJF': [12, 1, 2],
            'MAM': [3, 4, 5],
            'JJA': [6, 7, 8],
            'SON': [9, 10, 11]
        }
        
        result = {}
        
        # Extract month
        months = pd.DatetimeIndex(data[date_col]).month
        
        for season, season_months in season_map.items():
            season_data = data[months.isin(season_months)]
            if not season_data.empty:
                result[season] = season_data
        
        return result

#####################################
# Visualization Module
#####################################

class Visualization:
    """Visualization and plotting functions."""
    
    @staticmethod
    def setup_figure(figsize: Tuple[float, float] = (12, 8), style: str = 'seaborn-v0_8-whitegrid') -> Tuple[plt.Figure, plt.Axes]:
        """
        Set up a matplotlib figure with specified style.
        
        Args:
            figsize: Figure size (width, height) in inches
            style: Matplotlib style
            
        Returns:
            Figure and axes objects
        """
        plt.style.use(style)
        fig, ax = plt.subplots(figsize=figsize)
        return fig, ax
    
    @staticmethod
    def setup_multi_panel(nrows: int = 2, ncols: int = 2, figsize: Tuple[float, float] = (12, 8), 
                         height_ratios: List[float] = None, width_ratios: List[float] = None,
                         style: str = 'seaborn-v0_8-whitegrid') -> Tuple[plt.Figure, List[plt.Axes]]:
        """
        Set up multi-panel figure.
        
        Args:
            nrows: Number of rows
            ncols: Number of columns
            figsize: Figure size (width, height) in inches
            height_ratios: Relative heights of rows
            width_ratios: Relative widths of columns
            style: Matplotlib style
            
        Returns:
            Figure and list of axes objects
        """
        plt.style.use(style)
        fig = plt.figure(figsize=figsize)
        
        grid_kw = {}
        if height_ratios is not None:
            grid_kw['height_ratios'] = height_ratios
        if width_ratios is not None:
            grid_kw['width_ratios'] = width_ratios
            
        gs = gridspec.GridSpec(nrows, ncols, **grid_kw)
        
        axes = []
        for i in range(nrows):
            for j in range(ncols):
                axes.append(plt.subplot(gs[i, j]))
                
        return fig, axes
    
    @staticmethod
    def create_boxplot_comparison(ax: plt.Axes, data_dict: Dict[str, List[float]], labels: List[str], 
                               positions: np.ndarray, colors: List[str], width: float = 0.15, 
                               title: str = '', ylabel: str = '') -> None:
        """
        Create a comparison boxplot on the given axes.
        
        Args:
            ax: Matplotlib axes object
            data_dict: Dictionary with scenario names as keys and data lists as values
            labels: X-axis labels
            positions: X-axis positions
            colors: List of colors for each scenario
            width: Width of boxplots
            title: Plot title
            ylabel: Y-axis label
        """
        offset = -0.3
        
        for scenario, color in zip(data_dict.keys(), colors):
            bp = ax.boxplot([data_dict[scenario][i] for i, _ in enumerate(labels)],
                          positions=positions + offset,
                          widths=width,
                          patch_artist=True,
                          medianprops=dict(color='black'),
                          flierprops=dict(marker='o', markersize=4))
            
            for box in bp['boxes']:
                box.set(facecolor=color)
                
            offset += width
            
        ax.set_title(title, pad=10)
        ax.set_ylabel(ylabel)
        ax.set_xticks(positions)
        ax.set_xticklabels(labels)
    
    @staticmethod
    def create_bar_comparison(ax: plt.Axes, data_dict: Dict[str, List[float]], labels: List[str], 
                           colors: List[str], width: float = 0.15, title: str = '', 
                           ylabel: str = '') -> None:
        """
        Create a comparison bar chart on the given axes.
        
        Args:
            ax: Matplotlib axes object
            data_dict: Dictionary with scenario names as keys and data lists as values
            labels: X-axis labels
            colors: List of colors for each scenario
            width: Width of bars
            title: Plot title
            ylabel: Y-axis label
        """
        x = np.arange(len(labels))
        offset = -0.3
        
        for scenario, color in zip(data_dict.keys(), colors):
            ax.bar(x + offset, data_dict[scenario], width, color=color)
            offset += width
            
        ax.set_title(title)
        ax.set_ylabel(ylabel)
        ax.set_xticks(x)
        ax.set_xticklabels(labels)
    
    @staticmethod
    def plot_density_comparison(data_dict: Dict[str, np.ndarray], figsize: Tuple[float, float] = (10, 6),
                             title: str = 'Density Comparison', xlabel: str = 'Value', 
                             ylabel: str = 'Density', colors: List[str] = None) -> plt.Figure:
        """
        Create density plots for multiple datasets.
        
        Args:
            data_dict: Dictionary with dataset names as keys and data arrays as values
            figsize: Figure size (width, height) in inches
            title: Plot title
            xlabel: X-axis label
            ylabel: Y-axis label
            colors: List of colors for each dataset
            
        Returns:
            Matplotlib figure
        """
        fig, ax = plt.subplots(figsize=figsize)
        
        if colors is None:
            colors = plt.cm.tab10.colors[:len(data_dict)]
            
        for (name, data), color in zip(data_dict.items(), colors):
            clean_data = DataProcessing.remove_missing(data)
            ax.hist(clean_data, bins=30, density=True, alpha=0.5, color=color, label=name)
            
        ax.set_title(title)
        ax.set_xlabel(xlabel)
        ax.set_ylabel(ylabel)
        ax.legend()
        
        return fig
    
    @staticmethod
    def save_figure(fig: plt.Figure, filename: str, dpi: int = 300, bbox_inches: str = 'tight', 
                  formats: List[str] = ['png', 'pdf']) -> None:
        """
        Save figure in multiple formats.
        
        Args:
            fig: Matplotlib figure
            filename: Base filename without extension
            dpi: Resolution for raster formats
            bbox_inches: Bounding box specification
            formats: List of file formats to save
        """
        for fmt in formats:
            fig.savefig(f"{filename}.{fmt}", dpi=dpi if fmt != 'pdf' else None, 
                      bbox_inches=bbox_inches)

#####################################
# Statistics Module
#####################################

class Statistics:
    """Statistical analysis functions."""
    
    @staticmethod
    def calc_statistical_metrics(obs: np.ndarray, model: np.ndarray) -> Dict[str, float]:
        """
        Calculate statistical metrics between observations and model.
        
        Args:
            obs: Observation data
            model: Model data
            
        Returns:
            Dictionary with statistical metrics
        """
        # Remove NaN values
        valid = ~np.isnan(obs) & ~np.isnan(model)
        clean_obs = obs[valid]
        clean_model = model[valid]
        
        if len(clean_obs) == 0:
            return {
                'bias': np.nan,
                'rmse': np.nan, 
                'mae': np.nan,
                'correlation': np.nan,
                'n_points': 0
            }
        
        # Calculate metrics
        bias = np.mean(clean_model - clean_obs)
        rmse = np.sqrt(np.mean((clean_model - clean_obs)**2))
        mae = np.mean(np.abs(clean_model - clean_obs))
        corr = np.corrcoef(clean_obs, clean_model)[0, 1]
        
        return {
            'bias': bias,
            'rmse': rmse,
            'mae': mae,
            'correlation': corr,
            'n_points': len(clean_obs)
        }
    
    @staticmethod
    def compare_models(ref_data: np.ndarray, model_dict: Dict[str, np.ndarray]) -> pd.DataFrame:
        """
        Compare multiple models against reference data.
        
        Args:
            ref_data: Reference data array
            model_dict: Dictionary with model names as keys and data arrays as values
            
        Returns:
            DataFrame with statistical metrics for each model
        """
        results = []
        
        for model_name, model_data in model_dict.items():
            metrics = Statistics.calc_statistical_metrics(ref_data, model_data)
            metrics['model'] = model_name
            results.append(metrics)
            
        return pd.DataFrame(results)
    
    @staticmethod
    def calc_exceedance_stats(data_dict: Dict[str, np.ndarray], threshold: float = 120, 
                           by_season: bool = False, dates: pd.DatetimeIndex = None) -> Dict[str, Union[float, Dict[str, float]]]:
        """
        Calculate exceedance statistics for multiple datasets.
        
        Args:
            data_dict: Dictionary with dataset names as keys and data arrays as values
            threshold: Exceedance threshold
            by_season: Whether to calculate by season
            dates: DatetimeIndex corresponding to data (required if by_season=True)
            
        Returns:
            Dictionary with exceedance statistics
        """
        results = {}
        
        if by_season and dates is None:
            raise ValueError("Dates must be provided when calculating by season")
            
        for name, data in data_dict.items():
            exceedances = DataProcessing.calculate_exceedances(data, threshold)
            
            if not by_season:
                results[name] = np.sum(exceedances)
            else:
                season_results = {}
                season_map = {
                    'DJF': [12, 1, 2],
                    'MAM': [3, 4, 5],
                    'JJA': [6, 7, 8],
                    'SON': [9, 10, 11]
                }
                
                for season, months in season_map.items():
                    season_mask = np.array([m in months for m in dates.month])
                    season_results[season] = np.sum(exceedances[season_mask])
                    
                results[name] = season_results
                
        return results

#####################################
# Spatial Module
#####################################

class Spatial:
    """Geospatial functions."""
    
    @staticmethod
    def extract_points(raster_data: np.ndarray, lons: np.ndarray, lats: np.ndarray, 
                     points: List[Tuple[float, float]]) -> np.ndarray:
        """
        Extract values at specific points from a raster grid.
        
        Args:
            raster_data: 2D raster data array
            lons: 1D array of longitudes
            lats: 1D array of latitudes
            points: List of (lon, lat) point coordinates
            
        Returns:
            Array of extracted values
        """
        result = []
        
        for lon, lat in points:
            # Find nearest grid cell
            lon_idx = np.abs(lons - lon).argmin()
            lat_idx = np.abs(lats - lat).argmin()
            
            # Extract value
            if 0 <= lon_idx < raster_data.shape[1] and 0 <= lat_idx < raster_data.shape[0]:
                result.append(raster_data[lat_idx, lon_idx])
            else:
                result.append(np.nan)
                
        return np.array(result)
    
    @staticmethod
    def raster_difference(raster1: np.ndarray, raster2: np.ndarray) -> np.ndarray:
        """
        Calculate the difference between two rasters.
        
        Args:
            raster1: First raster array
            raster2: Second raster array
            
        Returns:
            Difference array (raster1 - raster2)
        """
        if raster1.shape != raster2.shape:
            raise ValueError(f"Raster shapes do not match: {raster1.shape} vs {raster2.shape}")
            
        return raster1 - raster2