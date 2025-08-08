#!/usr/bin/env python3
"""
GeoSphere Austria Dataset API Command-Line Interface

This application allows users to download meteorological and climatological data
from the GeoSphere Austria Dataset API through a text-based interface.
"""

import requests
import json
import pandas as pd
from datetime import datetime
import os
import argparse
import sys
import time
import concurrent.futures
import gc
import io


class GeosphereAPICLI:
    """
    Command-line interface for the GeoSphere Austria Dataset API.
    """

    def __init__(self, debug=False):
        """
        Initialize the CLI application.

        Parameters:
            debug (bool): Whether to enable debug output
        """
        # Constants
        self.BASE_URL = "https://dataset.api.hub.geosphere.at/v1"
        self.DATASETS_URL = f"{self.BASE_URL}/datasets"
        
        # App state
        self.debug_mode = debug
        self.datasets = {}
        self.selected_dataset = None
        self.selected_dataset_info = None
        self.selected_stations = []
        self.selected_parameters = []
        self.result_data = None
        self.bulk_download_cancel = False

    def debug_print(self, message):
        """
        Print debug messages if debug mode is enabled.

        Parameters:
            message (str): The debug message to print
        """
        if self.debug_mode:
            print(f"[DEBUG] {message}")

    def get_dataset_url(self, dataset_id):
        """
        Get the API URL for a specific dataset.
        
        Parameters:
            dataset_id (str): The dataset identifier
            
        Returns:
            str: The full API URL for the dataset
        """
        return f"{self.DATASETS_URL}/{dataset_id}"

    def print_status(self, message):
        """
        Print a status message.

        Parameters:
            message (str): The status message to display
        """
        print(f"[STATUS] {message}")

    def load_datasets(self):
        """
        Load available datasets from the API.
        
        Returns:
            bool: True if successful, False otherwise
        """
        self.print_status("Loading datasets...")
        try:
            response = requests.get(self.DATASETS_URL)
            if response.status_code == 200:
                data = response.json()
                # The API returns a dictionary with dataset paths as keys
                if isinstance(data, dict) and len(data) > 0:
                    # Convert the API response format to our internal format
                    self.datasets = {}
                    for path, details in data.items():
                        # Extract dataset ID from the path
                        dataset_id = path.split('/')[-1]
                        # Create a dataset entry with additional info from the details
                        self.datasets[dataset_id] = {
                            "id": dataset_id,
                            "path": path,
                            "title": dataset_id,  # Use ID as title if not provided
                            "url": details.get("url", f"{self.DATASETS_URL}/{dataset_id}"),
                            "type": details.get("type", "unknown"),
                            "mode": details.get("mode", "unknown"),
                            "response_formats": details.get("response_formats", [])
                        }
                    self.print_status(f"Loaded {len(self.datasets)} datasets")
                    return True
                else:
                    self.print_status("Error: Unexpected API response format")
            else:
                self.print_status(f"Error loading datasets: HTTP {response.status_code}")
        except Exception as e:
            self.print_status(f"Error: {str(e)}")
            import traceback
            traceback.print_exc()
        return False

    def list_datasets(self):
        """
        List all available datasets.
        """
        if not self.datasets:
            if not self.load_datasets():
                return
        
        print("\nAvailable datasets:")
        print("-" * 80)
        for idx, (dataset_id, dataset) in enumerate(self.datasets.items(), 1):
            print(f"{idx}. {dataset_id}: {dataset.get('title', 'No title')}")
        print("-" * 80)

    def select_dataset(self, dataset_id=None, dataset_idx=None):
        """
        Select a dataset by its ID or index.
        
        Parameters:
            dataset_id (str, optional): The dataset ID
            dataset_idx (int, optional): The index of the dataset in the list
            
        Returns:
            bool: True if successfully selected, False otherwise
        """
        if not self.datasets:
            if not self.load_datasets():
                return False
        
        if dataset_idx is not None:
            try:
                dataset_idx = int(dataset_idx)
                if 1 <= dataset_idx <= len(self.datasets):
                    dataset_id = list(self.datasets.keys())[dataset_idx - 1]
                else:
                    self.print_status(f"Error: Index {dataset_idx} out of range")
                    return False
            except ValueError:
                self.print_status("Error: Invalid dataset index")
                return False
        
        if dataset_id not in self.datasets:
            self.print_status(f"Error: Dataset '{dataset_id}' not found")
            return False
        
        self.selected_dataset = dataset_id
        self.print_status(f"Selected dataset: {dataset_id}")
        return self.fetch_metadata()

    def fetch_metadata(self):
        """
        Fetch metadata for the selected dataset.
        
        Returns:
            bool: True if successful, False otherwise
        """
        if not self.selected_dataset:
            self.print_status("Error: No dataset selected")
            return False
        
        # Get the URL from the dataset details
        if self.selected_dataset in self.datasets and "url" in self.datasets[self.selected_dataset]:
            url = self.datasets[self.selected_dataset]["url"]
        else:
            url = self.get_dataset_url(self.selected_dataset)
        
        self.print_status(f"Fetching metadata from {url}...")
        
        # Determine dataset type and prepare query params as needed
        dataset_type = self.datasets.get(self.selected_dataset, {}).get("type", "")
        
        # For station datasets, we need to provide parameters required by the API
        # This is just to get metadata, so we'll use dummy values
        params = {}
        if "station" in dataset_type.lower():
            # Get current date for start/end range
            from datetime import datetime, timedelta
            today = datetime.now().strftime("%Y-%m-%d")
            yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
            
            params = {
                "parameters": "t",  # Temperature as a common parameter
                "station_ids": "11035",  # Required format is a comma-separated list
                "start": yesterday,  # Required for some endpoints
                "end": today  # Required for some endpoints
            }
        
        try:
            response = requests.get(url, params=params)
            if response.status_code == 200:
                self.selected_dataset_info = response.json()
                self.debug_print(f"Metadata: {json.dumps(self.selected_dataset_info, indent=2)[:1000]}...")
                
                # Clear previous selections
                self.selected_parameters = []
                self.selected_stations = []
                
                self.print_status("Metadata fetched successfully")
                return True
            else:
                self.print_status(f"Error fetching metadata: HTTP {response.status_code}")
                self.debug_print(f"Error response: {response.text[:1000]}")
                
                # Handle various error scenarios
                if (response.status_code == 422 or response.status_code == 400) and "detail" in response.text:
                    try:
                        error_detail = json.loads(response.text)
                        
                        # Handle missing parameters or type errors
                        if isinstance(error_detail.get("detail"), list):
                            missing_params = []
                            type_errors = []
                            for error in error_detail["detail"]:
                                error_type = error.get("type", "")
                                if error_type == "missing" and len(error.get("loc", [])) > 1:
                                    missing_params.append(error["loc"][1])
                                elif error_type == "list_type" and len(error.get("loc", [])) > 1:
                                    type_errors.append(error["loc"][1])
                            
                            # Handle missing parameters
                            if missing_params:
                                self.debug_print(f"Missing required parameters: {', '.join(missing_params)}")
                                
                                # Try to add the missing parameters
                                for param in missing_params:
                                    if param == "start":
                                        params["start"] = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
                                    elif param == "end":
                                        params["end"] = datetime.now().strftime("%Y-%m-%d")
                                    elif param == "station_ids":
                                        params["station_ids"] = "11035"
                            
                            # Handle type errors
                            if type_errors:
                                self.debug_print(f"Type errors in parameters: {', '.join(type_errors)}")
                                
                                # Fix type errors
                                for param in type_errors:
                                    if param == "station_ids" and "station_ids" in params:
                                        # Make sure station_ids is a valid list format for API
                                        # For some endpoints, comma-separated IDs is what they expect
                                        params["station_ids"] = "11035"
                        
                        # Handle invalid station ID error
                        elif isinstance(error_detail.get("detail"), str) and "not allowed" in error_detail["detail"]:
                            self.debug_print("Invalid station ID provided. Trying with a different approach...")
                            # Instead of removing station_ids, try with an empty list which is still valid syntax
                            params["station_ids"] = ""
                                
                        self.print_status(f"Retrying with modified parameters...")
                        self.debug_print(f"Retry with params: {params}")
                        retry_response = requests.get(url, params=params)
                        if retry_response.status_code == 200:
                            self.selected_dataset_info = retry_response.json()
                            self.debug_print(f"Metadata: {json.dumps(self.selected_dataset_info, indent=2)[:1000]}...")
                            
                            # Clear previous selections
                            self.selected_parameters = []
                            self.selected_stations = []
                            
                            self.print_status("Metadata fetched successfully")
                            return True
                    except Exception as retry_err:
                        self.debug_print(f"Error during retry attempt: {str(retry_err)}")
        except Exception as e:
            self.print_status(f"Error: {str(e)}")
            import traceback
            traceback.print_exc()
        
        return False

    def list_parameters(self):
        """
        List available parameters for the selected dataset.
        """
        if not self.selected_dataset_info:
            self.print_status("Error: No dataset metadata available")
            # Try to fetch metadata if available
            if self.selected_dataset:
                if self.fetch_metadata():
                    self.print_status("Successfully retrieved metadata")
                else:
                    return
            else:
                return
        
        # Extract parameters from metadata
        parameters = []
        try:
            # Different APIs might have different response structures
            if 'parameters' in self.selected_dataset_info:
                parameters = self.selected_dataset_info['parameters']
            elif 'structure' in self.selected_dataset_info and 'parameters' in self.selected_dataset_info['structure']:
                parameters = self.selected_dataset_info['structure']['parameters']
            # Some APIs may have parameters in a "data" field
            elif isinstance(self.selected_dataset_info, dict) and 'data' in self.selected_dataset_info:
                data = self.selected_dataset_info['data']
                if isinstance(data, list) and len(data) > 0 and isinstance(data[0], dict) and 'parameter' in data[0]:
                    # Extract unique parameters
                    param_set = set()
                    for item in data:
                        if 'parameter' in item:
                            param_set.add(item['parameter'])
                        
                    # Convert to parameter objects
                    parameters = [{'id': param, 'name': param, 'unit': ''} for param in param_set]
            # Some APIs return a direct list of parameters
            elif isinstance(self.selected_dataset_info, list):
                # Try to determine if this is a parameter list
                if len(self.selected_dataset_info) > 0 and isinstance(self.selected_dataset_info[0], dict):
                    if 'id' in self.selected_dataset_info[0]:
                        parameters = self.selected_dataset_info
                    elif 'parameter' in self.selected_dataset_info[0]:
                        # Extract unique parameters
                        param_set = set()
                        for item in self.selected_dataset_info:
                            if 'parameter' in item:
                                param_set.add(item['parameter'])
                            
                        # Convert to parameter objects
                        parameters = [{'id': param, 'name': param, 'unit': ''} for param in param_set]
            # For some datasets, we might need to make a separate request for parameters
            if not parameters and self.selected_dataset and "type" in self.datasets.get(self.selected_dataset, {}):
                dataset_type = self.datasets[self.selected_dataset]["type"]
                if dataset_type == "station":
                    # Try to get parameter information via a different endpoint
                    self.print_status("Trying alternative method to retrieve parameters...")
                    try:
                        params_url = f"{self.BASE_URL}/parameters"
                        params_response = requests.get(params_url)
                        if params_response.status_code == 200:
                            params_data = params_response.json()
                            if isinstance(params_data, dict) and "parameters" in params_data:
                                parameters = params_data["parameters"]
                            elif isinstance(params_data, list):
                                parameters = params_data
                    except Exception as param_err:
                        self.debug_print(f"Error getting parameters from alternate endpoint: {str(param_err)}")
        except Exception as e:
            self.print_status(f"Error parsing parameters: {str(e)}")
            import traceback
            traceback.print_exc()
            return
        
        if not parameters:
            self.print_status("No parameters found in the dataset")
            return
        
        print("\nAvailable parameters:")
        print("-" * 80)
        for idx, param in enumerate(parameters, 1):
            param_id = param.get('id', 'Unknown')
            param_name = param.get('name', 'No name')
            param_unit = param.get('unit', 'No unit')
            selected = "X" if param_id in self.selected_parameters else " "
            print(f"{idx}. [{selected}] {param_id}: {param_name} ({param_unit})")
        print("-" * 80)

    def list_stations(self):
        """
        List available stations for the selected dataset.
        """
        if not self.selected_dataset_info:
            self.print_status("Error: No dataset metadata available")
            # Try to fetch metadata if available
            if self.selected_dataset:
                if self.fetch_metadata():
                    self.print_status("Successfully retrieved metadata")
                else:
                    return
            else:
                return
        
        # Extract stations from metadata
        stations = []
        try:
            if 'stations' in self.selected_dataset_info:
                stations = self.selected_dataset_info['stations']
            elif 'structure' in self.selected_dataset_info and 'stations' in self.selected_dataset_info['structure']:
                stations = self.selected_dataset_info['structure']['stations']
            # If we're dealing with a station dataset and the API returned a direct list
            elif isinstance(self.selected_dataset_info, list):
                # Try to determine if this is a station list
                if len(self.selected_dataset_info) > 0 and isinstance(self.selected_dataset_info[0], dict):
                    if 'id' in self.selected_dataset_info[0] and ('name' in self.selected_dataset_info[0] or 'state' in self.selected_dataset_info[0]):
                        stations = self.selected_dataset_info
                    elif 'station' in self.selected_dataset_info[0]:
                        # Extract unique station IDs
                        station_set = set()
                        for item in self.selected_dataset_info:
                            if 'station' in item:
                                station_set.add(item['station'])
                            
                        # Convert to station objects
                        stations = [{'id': station, 'name': station} for station in station_set]
            # Some APIs may have stations in a "data" field
            elif isinstance(self.selected_dataset_info, dict) and 'data' in self.selected_dataset_info:
                data = self.selected_dataset_info['data']
                if isinstance(data, list) and len(data) > 0 and isinstance(data[0], dict) and 'station' in data[0]:
                    # Extract unique station IDs
                    station_set = set()
                    for item in data:
                        if 'station' in item:
                            station_set.add(item['station'])
                        
                    # Convert to station objects
                    stations = [{'id': station, 'name': station} for station in station_set]
            
            # For some datasets, we might need to make a separate request for stations
            if not stations and self.selected_dataset and "type" in self.datasets.get(self.selected_dataset, {}):
                dataset_type = self.datasets[self.selected_dataset]["type"]
                if dataset_type == "station":
                    # Try to get station information via a different endpoint
                    self.print_status("Trying alternative method to retrieve stations...")
                    try:
                        stations_url = f"{self.BASE_URL}/stations"
                        stations_response = requests.get(stations_url)
                        if stations_response.status_code == 200:
                            stations_data = stations_response.json()
                            if isinstance(stations_data, dict) and "stations" in stations_data:
                                stations = stations_data["stations"]
                            elif isinstance(stations_data, list):
                                stations = stations_data
                    except Exception as station_err:
                        self.debug_print(f"Error getting stations from alternate endpoint: {str(station_err)}")
        except Exception as e:
            self.print_status(f"Error parsing stations: {str(e)}")
            import traceback
            traceback.print_exc()
            return
        
        if not stations:
            self.print_status("No stations found in the dataset")
            return
        
        print("\nAvailable stations:")
        print("-" * 80)
        for idx, station in enumerate(stations, 1):
            station_id = station.get('id', 'Unknown')
            station_name = station.get('name', 'No name')
            station_state = station.get('state', 'Unknown state')
            selected = "X" if station_id in self.selected_stations else " "
            print(f"{idx}. [{selected}] {station_id}: {station_name} ({station_state})")
        print("-" * 80)

    def select_parameters(self, param_indices=None, param_ids=None):
        """
        Select parameters for download.
        
        Parameters:
            param_indices (list, optional): List of parameter indices to select
            param_ids (list, optional): List of parameter IDs to select
            
        Returns:
            bool: True if parameters were selected, False otherwise
        """
        if not self.selected_dataset_info:
            self.print_status("Error: No dataset metadata available")
            return False
        
        # Extract parameters from metadata
        parameters = []
        try:
            if 'parameters' in self.selected_dataset_info:
                parameters = self.selected_dataset_info['parameters']
            elif 'structure' in self.selected_dataset_info and 'parameters' in self.selected_dataset_info['structure']:
                parameters = self.selected_dataset_info['structure']['parameters']
        except Exception as e:
            self.print_status(f"Error parsing parameters: {str(e)}")
            return False
        
        if not parameters:
            self.print_status("No parameters found in the dataset")
            return False
        
        # Clear previous selection if new selection is provided
        if param_indices or param_ids:
            self.selected_parameters = []
        
        # Select by indices
        if param_indices:
            for idx_str in param_indices:
                try:
                    idx = int(idx_str)
                    if 1 <= idx <= len(parameters):
                        param_id = parameters[idx - 1].get('id')
                        if param_id and param_id not in self.selected_parameters:
                            self.selected_parameters.append(param_id)
                    else:
                        self.print_status(f"Warning: Parameter index {idx} out of range")
                except ValueError:
                    self.print_status(f"Warning: Invalid parameter index '{idx_str}'")
        
        # Select by IDs
        if param_ids:
            param_id_list = [p.get('id') for p in parameters]
            for param_id in param_ids:
                if param_id in param_id_list and param_id not in self.selected_parameters:
                    self.selected_parameters.append(param_id)
                else:
                    self.print_status(f"Warning: Parameter ID '{param_id}' not found")
        
        self.print_status(f"Selected parameters: {', '.join(self.selected_parameters)}")
        return len(self.selected_parameters) > 0

    def select_stations(self, station_indices=None, station_ids=None):
        """
        Select stations for download.
        
        Parameters:
            station_indices (list, optional): List of station indices to select
            station_ids (list, optional): List of station IDs to select
            
        Returns:
            bool: True if stations were selected, False otherwise
        """
        if not self.selected_dataset_info:
            self.print_status("Error: No dataset metadata available")
            return False
        
        # Extract stations from metadata
        stations = []
        try:
            if 'stations' in self.selected_dataset_info:
                stations = self.selected_dataset_info['stations']
            elif 'structure' in self.selected_dataset_info and 'stations' in self.selected_dataset_info['structure']:
                stations = self.selected_dataset_info['structure']['stations']
        except Exception as e:
            self.print_status(f"Error parsing stations: {str(e)}")
            return False
        
        if not stations:
            self.print_status("No stations found in the dataset")
            return False
        
        # Clear previous selection if new selection is provided
        if station_indices or station_ids:
            self.selected_stations = []
        
        # Select by indices
        if station_indices:
            for idx_str in station_indices:
                try:
                    idx = int(idx_str)
                    if 1 <= idx <= len(stations):
                        station_id = stations[idx - 1].get('id')
                        if station_id and station_id not in self.selected_stations:
                            self.selected_stations.append(station_id)
                    else:
                        self.print_status(f"Warning: Station index {idx} out of range")
                except ValueError:
                    self.print_status(f"Warning: Invalid station index '{idx_str}'")
        
        # Select by IDs
        if station_ids:
            station_id_list = [s.get('id') for s in stations]
            for station_id in station_ids:
                if station_id in station_id_list and station_id not in self.selected_stations:
                    self.selected_stations.append(station_id)
                else:
                    self.print_status(f"Warning: Station ID '{station_id}' not found")
        
        self.print_status(f"Selected stations: {', '.join(self.selected_stations)}")
        return len(self.selected_stations) > 0

    def download_data(self, start_date=None, end_date=None, output_format="csv", output_file=None):
        """
        Download data for the selected parameters and stations.
        
        Parameters:
            start_date (str, optional): Start date in YYYY-MM-DD format
            end_date (str, optional): End date in YYYY-MM-DD format
            output_format (str, optional): Output format (csv or geojson)
            output_file (str, optional): Path to save the downloaded data
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not self.selected_dataset:
            self.print_status("Error: No dataset selected")
            return False
        
        if not self.selected_parameters:
            self.print_status("Error: No parameters selected")
            return False
        
        if not self.selected_stations:
            self.print_status("Error: No stations selected")
            return False
        
        # Prepare query parameters
        params = {
            "parameters": ",".join(self.selected_parameters),
            "station_ids": ",".join(self.selected_stations),
            "output_format": output_format
        }
        
        # Add date range if specified
        if start_date:
            try:
                # Validate date format
                datetime.strptime(start_date, "%Y-%m-%d")
                params["start"] = start_date
            except ValueError:
                self.print_status("Error: Invalid start date format. Use YYYY-MM-DD.")
                return False
        
        if end_date:
            try:
                # Validate date format
                datetime.strptime(end_date, "%Y-%m-%d")
                params["end"] = end_date
            except ValueError:
                self.print_status("Error: Invalid end date format. Use YYYY-MM-DD.")
                return False
        
        # Get the API URL
        if self.selected_dataset in self.datasets and 'url' in self.datasets[self.selected_dataset]:
            url = self.datasets[self.selected_dataset]['url']
        elif isinstance(self.selected_dataset_info, dict) and 'url' in self.selected_dataset_info:
            url = self.selected_dataset_info['url']
        else:
            url = self.get_dataset_url(self.selected_dataset)
            
        # For historical data, we need date ranges
        dataset_mode = self.datasets.get(self.selected_dataset, {}).get("mode", "")
        if "historical" in dataset_mode.lower() or "station" in self.datasets.get(self.selected_dataset, {}).get("type", "").lower():
            if "start" not in params:
                # Add default date range (yesterday to today)
                from datetime import datetime, timedelta
                if start_date:
                    params["start"] = start_date
                else:
                    params["start"] = (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
                    
                if end_date:
                    params["end"] = end_date
                else:
                    params["end"] = datetime.now().strftime("%Y-%m-%d")
                
            # Validate that we have valid station IDs for station datasets
            if "station" in self.datasets.get(self.selected_dataset, {}).get("type", "").lower():
                if not self.selected_stations:
                    self.print_status("Warning: No stations selected for station dataset. This request may fail.")
        
        # Download data
        self.print_status(f"Downloading data from {url}...")
        self.debug_print(f"Request URL: {url}")
        self.debug_print(f"Request params: {params}")
        
        try:
            response = requests.get(url, params=params)
            
            if response.status_code == 200:
                # Process based on content type
                content_type = response.headers.get('Content-Type', '')
                self.debug_print(f"Response content type: {content_type}")
                
                if 'json' in content_type:
                    self.result_data = response.json()
                    data_size = len(str(self.result_data))
                    self.debug_print(f"Downloaded JSON data ({data_size} characters)")
                elif 'csv' in content_type:
                    # Parse CSV data
                    csv_data = pd.read_csv(io.StringIO(response.text))
                    self.result_data = csv_data
                    self.debug_print(f"Downloaded CSV data ({len(response.text)} characters, {len(csv_data)} rows)")
                else:
                    # Store raw data
                    self.result_data = response.text
                    self.debug_print(f"Downloaded raw data ({len(response.text)} characters)")
                
                self.print_status("Data downloaded successfully")
                
                # Save to file if requested
                if output_file:
                    return self.save_data(output_file)
                return True
            else:
                self.print_status(f"Error downloading data: HTTP {response.status_code}")
                self.debug_print(f"Error response: {response.text[:1000]}")
        except Exception as e:
            self.print_status(f"Error: {str(e)}")
            import traceback
            traceback.print_exc()
        
        return False

    def save_data(self, output_file):
        """
        Save the downloaded data to a file.
        
        Parameters:
            output_file (str): Path to save the data
            
        Returns:
            bool: True if successful, False otherwise
        """
        if self.result_data is None:
            self.print_status("Error: No data to save")
            return False
        
        try:
            # Create directories if they don't exist
            os.makedirs(os.path.dirname(os.path.abspath(output_file)), exist_ok=True)
            
            # Save based on the data type
            if isinstance(self.result_data, pd.DataFrame):
                # For pandas DataFrame (CSV data)
                if output_file.lower().endswith('.csv'):
                    self.result_data.to_csv(output_file, index=False)
                else:
                    # Default to CSV if no extension matches
                    self.result_data.to_csv(output_file, index=False)
                    
            elif isinstance(self.result_data, dict):
                # For JSON data
                if output_file.lower().endswith('.json'):
                    with open(output_file, 'w') as f:
                        json.dump(self.result_data, f, indent=2)
                else:
                    # Default to JSON
                    with open(output_file, 'w') as f:
                        json.dump(self.result_data, f, indent=2)
            else:
                # For raw text data
                with open(output_file, 'w') as f:
                    f.write(str(self.result_data))
            
            self.print_status(f"Data saved to {output_file}")
            return True
            
        except Exception as e:
            self.print_status(f"Error saving data: {str(e)}")
            return False

    def bulk_download(self, start_date=None, end_date=None, output_format="csv", output_dir=None, max_workers=3):
        """
        Download data for all selected stations and parameters, one parameter at a time.
        
        Parameters:
            start_date (str, optional): Start date in YYYY-MM-DD format
            end_date (str, optional): End date in YYYY-MM-DD format
            output_format (str, optional): Output format (csv or geojson)
            output_dir (str, optional): Directory to save the downloaded data files
            max_workers (int, optional): Maximum number of parallel download workers
            
        Returns:
            bool: True if successful, False otherwise
        """
        if not self.selected_dataset:
            self.print_status("Error: No dataset selected")
            return False
        
        if not self.selected_parameters:
            self.print_status("Error: No parameters selected")
            return False
        
        if not self.selected_stations:
            self.print_status("Error: No stations selected")
            return False
        
        # Create output directory if it doesn't exist
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        # Reset cancel flag
        self.bulk_download_cancel = False
        
        # Prepare URL
        if isinstance(self.selected_dataset_info, dict) and 'url' in self.selected_dataset_info:
            url = self.selected_dataset_info['url']
        else:
            url = self.get_dataset_url(self.selected_dataset)
        
        # Prepare common query parameters
        base_params = {
            "output_format": output_format,
            "station_ids": ",".join(self.selected_stations)
        }
        
        # Add date range if specified
        if start_date:
            try:
                datetime.strptime(start_date, "%Y-%m-%d")
                base_params["start"] = start_date
            except ValueError:
                self.print_status("Error: Invalid start date format. Use YYYY-MM-DD.")
                return False
        
        if end_date:
            try:
                datetime.strptime(end_date, "%Y-%m-%d")
                base_params["end"] = end_date
            except ValueError:
                self.print_status("Error: Invalid end date format. Use YYYY-MM-DD.")
                return False
        
        # Prepare download tasks
        download_tasks = []
        for param in self.selected_parameters:
            task_params = base_params.copy()
            task_params["parameters"] = param
            
            # Generate output filename if directory is provided
            output_file = None
            if output_dir:
                if start_date and end_date:
                    date_part = f"{start_date}_to_{end_date}"
                else:
                    date_part = datetime.now().strftime("%Y%m%d")
                
                filename = f"{self.selected_dataset}_{param}_{date_part}.{output_format}"
                output_file = os.path.join(output_dir, filename)
            
            download_tasks.append((url, task_params, param, output_file))
        
        self.print_status(f"Starting bulk download of {len(download_tasks)} parameters...")
        
        # Use concurrent.futures for parallel downloads
        start_time = time.time()
        completed = 0
        total_tasks = len(download_tasks)
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            # Submit all tasks
            futures = {executor.submit(self._download_single_parameter, *task): task[2] for task in download_tasks}
            
            # Process completed tasks
            for future in concurrent.futures.as_completed(futures):
                param = futures[future]
                try:
                    success = future.result()
                    completed += 1
                    
                    # Calculate progress and ETA
                    elapsed = time.time() - start_time
                    progress = completed / total_tasks
                    eta = (elapsed / progress) * (1 - progress) if progress > 0 else 0
                    
                    if success:
                        self.print_status(f"Progress: {completed}/{total_tasks} ({progress:.1%}) - "
                                          f"ETA: {eta:.1f}s - Downloaded {param}")
                    else:
                        self.print_status(f"Progress: {completed}/{total_tasks} ({progress:.1%}) - "
                                          f"ETA: {eta:.1f}s - Failed to download {param}")
                    
                    # Release memory
                    gc.collect()
                    
                    # Check for cancellation
                    if self.bulk_download_cancel:
                        self.print_status("Bulk download cancelled")
                        for f in futures:
                            f.cancel()
                        return False
                        
                except Exception as e:
                    self.print_status(f"Error downloading {param}: {str(e)}")
        
        total_time = time.time() - start_time
        self.print_status(f"Bulk download completed in {total_time:.1f} seconds")
        return True

    def _download_single_parameter(self, url, params, param, output_file=None):
        """
        Download data for a single parameter.
        
        Parameters:
            url (str): The API URL
            params (dict): The query parameters
            param (str): The parameter ID (for logging)
            output_file (str, optional): Path to save the downloaded data
            
        Returns:
            bool: True if successful, False otherwise
        """
        try:
            self.debug_print(f"Downloading parameter {param}")
            response = requests.get(url, params=params)
            
            if response.status_code == 200:
                # Save data if output file is specified
                if output_file:
                    content_type = response.headers.get('Content-Type', '')
                    
                    if 'json' in content_type:
                        data = response.json()
                        with open(output_file, 'w') as f:
                            json.dump(data, f, indent=2)
                    elif 'csv' in content_type:
                        # For CSV data
                        with open(output_file, 'w') as f:
                            f.write(response.text)
                    else:
                        # For raw data
                        with open(output_file, 'wb') as f:
                            f.write(response.content)
                    
                    self.debug_print(f"Saved parameter {param} to {output_file}")
                return True
            else:
                self.debug_print(f"Error downloading parameter {param}: HTTP {response.status_code}")
                return False
        except Exception as e:
            self.debug_print(f"Exception downloading parameter {param}: {str(e)}")
            return False

    def test_api_connection(self):
        """
        Test the connection to the API.
        
        Returns:
            bool: True if connected, False otherwise
        """
        self.print_status("Testing API connection...")
        try:
            response = requests.get(self.DATASETS_URL)
            if response.status_code == 200:
                data = response.json()
                count = len(data) if isinstance(data, dict) else 0
                self.print_status(f"API connection successful - found {count} datasets")
                return True
            else:
                self.print_status(f"API connection failed: HTTP {response.status_code}")
                self.debug_print(f"Error response: {response.text[:1000]}")
        except Exception as e:
            self.print_status(f"API connection error: {str(e)}")
            import traceback
            traceback.print_exc()
        return False

    def interactive_mode(self):
        """
        Run the application in interactive mode.
        """
        print("\nGeoSphere Austria Dataset API CLI")
        print("=" * 80)
        print("Type 'help' or '?' for available commands")
        
        while True:
            try:
                command = input("\nCommand> ").strip()
                parts = command.split()
                
                if not parts:
                    continue
                
                cmd = parts[0].lower()
                args = parts[1:]
                
                if cmd in ('quit', 'exit', 'q'):
                    break
                elif cmd in ('help', '?'):
                    self._print_help()
                elif cmd == 'datasets':
                    self.list_datasets()
                elif cmd == 'select':
                    if len(args) < 1:
                        print("Error: Missing dataset ID or index")
                        print("Usage: select <dataset_id|index>")
                    else:
                        # Try to interpret as index first
                        try:
                            idx = int(args[0])
                            self.select_dataset(dataset_idx=idx)
                        except ValueError:
                            # Not an index, treat as ID
                            self.select_dataset(dataset_id=args[0])
                elif cmd == 'parameters':
                    self.list_parameters()
                elif cmd == 'stations':
                    self.list_stations()
                elif cmd == 'selectparam':
                    if len(args) < 1:
                        print("Error: Missing parameter indices or IDs")
                        print("Usage: selectparam <idx1 idx2 ... | id1 id2 ...>")
                    else:
                        # Try to interpret as indices first
                        try:
                            indices = [int(a) for a in args]
                            self.select_parameters(param_indices=args)
                        except ValueError:
                            # Not all indices, treat as IDs
                            self.select_parameters(param_ids=args)
                elif cmd == 'selectstation':
                    if len(args) < 1:
                        print("Error: Missing station indices or IDs")
                        print("Usage: selectstation <idx1 idx2 ... | id1 id2 ...>")
                    else:
                        # Try to interpret as indices first
                        try:
                            indices = [int(a) for a in args]
                            self.select_stations(station_indices=args)
                        except ValueError:
                            # Not all indices, treat as IDs
                            self.select_stations(station_ids=args)
                elif cmd == 'download':
                    start_date = None
                    end_date = None
                    output_format = "csv"
                    output_file = None
                    
                    # Parse arguments
                    i = 0
                    while i < len(args):
                        if args[i] == '--start':
                            if i + 1 < len(args):
                                start_date = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --start")
                                break
                        elif args[i] == '--end':
                            if i + 1 < len(args):
                                end_date = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --end")
                                break
                        elif args[i] == '--format':
                            if i + 1 < len(args):
                                output_format = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --format")
                                break
                        elif args[i] == '--output':
                            if i + 1 < len(args):
                                output_file = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --output")
                                break
                        else:
                            print(f"Warning: Unknown argument '{args[i]}'")
                            i += 1
                    
                    self.download_data(start_date, end_date, output_format, output_file)
                elif cmd == 'bulkdownload':
                    start_date = None
                    end_date = None
                    output_format = "csv"
                    output_dir = None
                    max_workers = 3
                    
                    # Parse arguments
                    i = 0
                    while i < len(args):
                        if args[i] == '--start':
                            if i + 1 < len(args):
                                start_date = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --start")
                                break
                        elif args[i] == '--end':
                            if i + 1 < len(args):
                                end_date = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --end")
                                break
                        elif args[i] == '--format':
                            if i + 1 < len(args):
                                output_format = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --format")
                                break
                        elif args[i] == '--output-dir':
                            if i + 1 < len(args):
                                output_dir = args[i + 1]
                                i += 2
                            else:
                                print("Error: Missing value for --output-dir")
                                break
                        elif args[i] == '--workers':
                            if i + 1 < len(args):
                                try:
                                    max_workers = int(args[i + 1])
                                    i += 2
                                except ValueError:
                                    print("Error: Invalid value for --workers, must be an integer")
                                    break
                            else:
                                print("Error: Missing value for --workers")
                                break
                        else:
                            print(f"Warning: Unknown argument '{args[i]}'")
                            i += 1
                    
                    self.bulk_download(start_date, end_date, output_format, output_dir, max_workers)
                elif cmd == 'test':
                    self.test_api_connection()
                elif cmd == 'debug':
                    if len(args) > 0 and args[0].lower() in ('on', 'true', '1', 'yes'):
                        self.debug_mode = True
                        print("Debug mode enabled")
                    elif len(args) > 0 and args[0].lower() in ('off', 'false', '0', 'no'):
                        self.debug_mode = False
                        print("Debug mode disabled")
                    else:
                        print(f"Debug mode is currently {'enabled' if self.debug_mode else 'disabled'}")
                else:
                    print(f"Unknown command: {cmd}")
            except KeyboardInterrupt:
                print("\nOperation cancelled by user")
            except Exception as e:
                print(f"Error executing command: {str(e)}")
        
        print("Exiting GeoSphere Austria Dataset API CLI")

    def _print_help(self):
        """
        Print the help message with available commands.
        """
        print("\nAvailable commands:")
        print("-" * 80)
        print("help, ?                                   Show this help message")
        print("datasets                                  List available datasets")
        print("select <dataset_id|index>                Select a dataset by ID or index")
        print("parameters                               List parameters for the selected dataset")
        print("stations                                 List stations for the selected dataset")
        print("selectparam <idx1 idx2 ... | id1 id2 ...> Select parameters by indices or IDs")
        print("selectstation <idx1 idx2 ... | id1 id2 ...> Select stations by indices or IDs")
        print("download [options]                       Download data for selected parameters and stations")
        print("  --start YYYY-MM-DD                      Start date for the data")
        print("  --end YYYY-MM-DD                        End date for the data")
        print("  --format csv|geojson                    Output format (default: csv)")
        print("  --output FILE                           Save output to file")
        print("bulkdownload [options]                   Download each parameter in separate files")
        print("  --start YYYY-MM-DD                      Start date for the data")
        print("  --end YYYY-MM-DD                        End date for the data")
        print("  --format csv|geojson                    Output format (default: csv)")
        print("  --output-dir DIRECTORY                  Directory to save output files")
        print("  --workers N                             Maximum parallel downloads (default: 3)")
        print("test                                     Test API connection")
        print("debug [on|off]                           Show or set debug mode")
        print("quit, exit, q                            Exit the application")
        print("-" * 80)


def parse_args():
    """
    Parse command line arguments.
    
    Returns:
        argparse.Namespace: The parsed arguments
    """
    parser = argparse.ArgumentParser(description="GeoSphere Austria Dataset API CLI")
    parser.add_argument('--debug', action='store_true', help='Enable debug output')
    parser.add_argument('--interactive', action='store_true', help='Run in interactive mode')
    
    # Non-interactive mode arguments
    parser.add_argument('--dataset', help='Dataset ID')
    parser.add_argument('--parameters', help='Comma-separated list of parameter IDs')
    parser.add_argument('--stations', help='Comma-separated list of station IDs')
    parser.add_argument('--start-date', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end-date', help='End date (YYYY-MM-DD)')
    parser.add_argument('--format', choices=['csv', 'geojson'], default='csv', help='Output format')
    parser.add_argument('--output', help='Output file')
    parser.add_argument('--bulk', action='store_true', help='Perform bulk download')
    parser.add_argument('--output-dir', help='Output directory for bulk download')
    parser.add_argument('--workers', type=int, default=3, help='Maximum parallel workers for bulk download')
    parser.add_argument('--list-parameters', action='store_true', help='List parameters for the selected dataset and exit')
    parser.add_argument('--list-stations', action='store_true', help='List stations for the selected dataset and exit')
    
    return parser.parse_args()


def main():
    """
    Main entry point.
    """
    args = parse_args()
    
    # Create the CLI application
    app = GeosphereAPICLI(debug=args.debug)
    
    # Run in interactive mode if specified or if no other arguments provided
    if args.interactive or (not args.dataset and not args.parameters and not args.stations and 
                           not args.list_parameters and not args.list_stations):
        app.interactive_mode()
        return
    
    # Non-interactive mode
    if not args.dataset:
        print("Error: --dataset is required in non-interactive mode")
        return
    
    # Load datasets and select the specified one
    app.load_datasets()
    if not app.select_dataset(dataset_id=args.dataset):
        print(f"Error: Could not select dataset '{args.dataset}'")
        return
        
    # Special list operations
    if args.list_parameters:
        app.list_parameters()
        return
        
    if args.list_stations:
        app.list_stations()
        return
    
    # Select parameters if specified
    if args.parameters:
        param_ids = args.parameters.split(',')
        if not app.select_parameters(param_ids=param_ids):
            print("Error: Could not select parameters")
            return
    
    # Select stations if specified
    if args.stations:
        station_ids = args.stations.split(',')
        if not app.select_stations(station_ids=station_ids):
            print("Error: Could not select stations")
            return
    
    # Download data
    if args.bulk:
        app.bulk_download(
            start_date=args.start_date,
            end_date=args.end_date,
            output_format=args.format,
            output_dir=args.output_dir,
            max_workers=args.workers
        )
    else:
        app.download_data(
            start_date=args.start_date,
            end_date=args.end_date,
            output_format=args.format,
            output_file=args.output
        )


if __name__ == "__main__":
    main()