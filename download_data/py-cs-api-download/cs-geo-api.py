import tkinter as tk
from tkinter import ttk, filedialog, messagebox
import requests
import json
import pandas as pd
from datetime import datetime
import os
import threading
import io

class GeosphereAPIApp:
    """
    GeoSphere Austria Dataset API GUI Application

    This application allows users to download meteorological and climatological data
    from the GeoSphere Austria Dataset API.
    """

    def __init__(self, root):
        self.root = root
        self.root.title("GeoSphere Austria Dataset API Explorer")
        self.root.geometry("1000x700")
        self.root.minsize(800, 600)

        # Constants
        self.BASE_URL = "https://dataset.api.hub.geosphere.at/v1"
        self.DATASETS_URL = f"{self.BASE_URL}/datasets"

        # Enable debug mode
        self.debug_mode = True

        # App state
        self.datasets = {}
        self.selected_dataset = None
        self.selected_dataset_info = None
        self.selected_stations = []
        self.selected_parameters = []
        self.result_data = None
        self.status_message = "Ready"
        self.is_bulk_downloading = False
        self.bulk_download_cancel = False

        # Create UI
        self.create_ui()

    def debug_print(self, *args, **kwargs):
        """Print debug information if debug mode is enabled"""
        if self.debug_mode:
            print(*args, **kwargs)

    def get_dataset_url(self, dataset_key):
        """Construct a proper URL for a dataset"""
        # If the key starts with /, remove it to avoid double slashes
        if dataset_key.startswith('/'):
            dataset_key = dataset_key[1:]

        return f"{self.BASE_URL}/{dataset_key}"

    def create_ui(self):
        """Create the user interface components"""
        # Main container
        main_frame = ttk.Frame(self.root, padding="10")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Header
        header_label = ttk.Label(main_frame, text="GeoSphere Austria Dataset API Explorer",
                                font=("TkDefaultFont", 14, "bold"))
        header_label.pack(pady=(0, 10))

        # Content area (3-column layout)
        content_frame = ttk.Frame(main_frame)
        content_frame.pack(fill=tk.BOTH, expand=True, pady=5)

        # Left panel - Dataset selection
        left_frame = ttk.LabelFrame(content_frame, text="Datasets")
        left_frame.grid(row=0, column=0, padx=5, pady=5, sticky="nsew")

        # Dataset listbox with scrollbar
        datasets_frame = ttk.Frame(left_frame)
        datasets_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        self.dataset_listbox = tk.Listbox(datasets_frame, selectmode=tk.SINGLE)
        self.dataset_listbox.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        dataset_scrollbar = ttk.Scrollbar(datasets_frame, orient=tk.VERTICAL,
                                         command=self.dataset_listbox.yview)
        dataset_scrollbar.pack(side=tk.RIGHT, fill=tk.Y)
        self.dataset_listbox.config(yscrollcommand=dataset_scrollbar.set)

        # Load datasets button
        load_btn = ttk.Button(left_frame, text="Load Datasets", command=self.load_datasets)
        load_btn.pack(padx=5, pady=5, fill=tk.X)

        # Bind selection event
        self.dataset_listbox.bind('<<ListboxSelect>>', self.on_dataset_select)

        # Middle panel - Parameters and stations
        middle_frame = ttk.Frame(content_frame)
        middle_frame.grid(row=0, column=1, padx=5, pady=5, sticky="nsew")

        # Parameters frame
        params_frame = ttk.LabelFrame(middle_frame, text="Parameters")
        params_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        params_canvas = tk.Canvas(params_frame)
        params_scrollbar = ttk.Scrollbar(params_frame, orient="vertical", command=params_canvas.yview)
        self.params_frame = ttk.Frame(params_canvas)

        self.params_frame.bind(
            "<Configure>",
            lambda e: params_canvas.configure(scrollregion=params_canvas.bbox("all"))
        )

        params_canvas.create_window((0, 0), window=self.params_frame, anchor="nw")
        params_canvas.configure(yscrollcommand=params_scrollbar.set)

        params_canvas.pack(side="left", fill="both", expand=True)
        params_scrollbar.pack(side="right", fill="y")

        # Stations frame
        stations_frame = ttk.LabelFrame(middle_frame, text="Stations")
        stations_frame.pack(fill=tk.BOTH, expand=True, padx=5, pady=5)

        stations_canvas = tk.Canvas(stations_frame)
        stations_scrollbar = ttk.Scrollbar(stations_frame, orient="vertical", command=stations_canvas.yview)
        self.stations_frame = ttk.Frame(stations_canvas)

        self.stations_frame.bind(
            "<Configure>",
            lambda e: stations_canvas.configure(scrollregion=stations_canvas.bbox("all"))
        )

        stations_canvas.create_window((0, 0), window=self.stations_frame, anchor="nw")
        stations_canvas.configure(yscrollcommand=stations_scrollbar.set)

        stations_canvas.pack(side="left", fill="both", expand=True)
        stations_scrollbar.pack(side="right", fill="y")

        # Right panel - Query options
        right_frame = ttk.LabelFrame(content_frame, text="Query Options")
        right_frame.grid(row=0, column=2, padx=5, pady=5, sticky="nsew")

        # Configure grid weights
        content_frame.columnconfigure(0, weight=1)  # Left panel
        content_frame.columnconfigure(1, weight=2)  # Middle panel
        content_frame.columnconfigure(2, weight=1)  # Right panel
        content_frame.rowconfigure(0, weight=1)

        # Date range section
        date_frame = ttk.Frame(right_frame)
        date_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Label(date_frame, text="Start Date:").grid(row=0, column=0, sticky="w", pady=2)
        self.start_date_entry = ttk.Entry(date_frame)
        self.start_date_entry.grid(row=0, column=1, sticky="ew", pady=2)
        self.start_date_entry.insert(0, "YYYY-MM-DD")

        ttk.Label(date_frame, text="End Date:").grid(row=1, column=0, sticky="w", pady=2)
        self.end_date_entry = ttk.Entry(date_frame)
        self.end_date_entry.grid(row=1, column=1, sticky="ew", pady=2)
        self.end_date_entry.insert(0, "YYYY-MM-DD")

        # Format selection
        format_frame = ttk.Frame(right_frame)
        format_frame.pack(fill=tk.X, padx=5, pady=5)

        ttk.Label(format_frame, text="Output Format:").grid(row=0, column=0, sticky="w", pady=2)
        self.format_combo = ttk.Combobox(format_frame, values=["csv", "geojson"])
        self.format_combo.grid(row=0, column=1, sticky="ew", pady=2)
        self.format_combo.current(0)  # Set default to CSV

        # Action buttons
        buttons_frame = ttk.Frame(right_frame)
        buttons_frame.pack(fill=tk.X, padx=5, pady=10)

        self.download_btn = ttk.Button(buttons_frame, text="Download Data", command=self.download_data)
        self.download_btn.pack(fill=tk.X, pady=2)

        self.bulk_download_btn = ttk.Button(buttons_frame, text="Bulk Download All Parameters",
                                           command=self.start_bulk_download)
        self.bulk_download_btn.pack(fill=tk.X, pady=2)

        self.save_btn = ttk.Button(buttons_frame, text="Save Data to File", command=self.save_data)
        self.save_btn.pack(fill=tk.X, pady=2)

        # Add a debug/testing section
        debug_frame = ttk.LabelFrame(right_frame, text="Debugging")
        debug_frame.pack(fill=tk.X, padx=5, pady=10)

        # Toggle debug mode
        self.debug_var = tk.BooleanVar(value=True)
        debug_check = ttk.Checkbutton(debug_frame, text="Enable Debug Mode",
                                     variable=self.debug_var,
                                     command=self.toggle_debug_mode)
        debug_check.pack(fill=tk.X, pady=2)

        # Test connection button
        test_btn = ttk.Button(debug_frame, text="Test API Connection", command=self.test_api_connection)
        test_btn.pack(fill=tk.X, pady=2)

        # Show API response button
        show_response_btn = ttk.Button(debug_frame, text="Show API Response",
                                      command=self.show_api_response)
        show_response_btn.pack(fill=tk.X, pady=2)

        # Status bar
        self.status_bar = ttk.Label(main_frame, text="Ready", relief=tk.SUNKEN, anchor=tk.W)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X, pady=5)

    def toggle_debug_mode(self):
        """Toggle debug mode on/off"""
        self.debug_mode = self.debug_var.get()
        self.debug_print(f"Debug mode {'enabled' if self.debug_mode else 'disabled'}")

    def test_api_connection(self):
        """Test the connection to the API endpoints"""
        self.set_status("Testing API connection...")

        endpoints = [
            ("Main API", self.BASE_URL),
            ("Datasets", self.DATASETS_URL)
        ]

        results = []

        for name, url in endpoints:
            try:
                response = requests.get(url)
                status = response.status_code
                results.append(f"{name}: {status} ({'OK' if status == 200 else 'FAIL'})")
            except Exception as e:
                results.append(f"{name}: Error - {str(e)}")

        # Show the results in a dialog
        result_text = "\n".join(results)
        messagebox.showinfo("API Connection Test", result_text)

        self.set_status("API connection test completed")

    def show_api_response(self):
        """Show the raw API response for debugging"""
        if not self.selected_dataset:
            messagebox.showinfo("Info", "Please select a dataset first")
            return

        # Create a dialog to show the response
        response_window = tk.Toplevel(self.root)
        response_window.title(f"API Response: {self.selected_dataset}")
        response_window.geometry("800x600")

        # Create a frame with scrollbar
        frame = ttk.Frame(response_window)
        frame.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)

        # Add a text widget with scrollbar
        text_widget = tk.Text(frame, wrap=tk.WORD)
        scrollbar = ttk.Scrollbar(frame, orient="vertical", command=text_widget.yview)
        text_widget.configure(yscrollcommand=scrollbar.set)

        text_widget.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

        # Fetch the dataset metadata
        try:
            if isinstance(self.selected_dataset_info, dict) and 'url' in self.selected_dataset_info:
                base_url = self.selected_dataset_info['url']
            else:
                base_url = self.get_dataset_url(self.selected_dataset)

            url = f"{base_url}/metadata"

            text_widget.insert(tk.END, f"Fetching data from: {url}\n\n")

            response = requests.get(url)

            text_widget.insert(tk.END, f"Status Code: {response.status_code}\n\n")
            text_widget.insert(tk.END, f"Headers:\n{response.headers}\n\n")

            if response.status_code == 200:
                try:
                    data = response.json()
                    text_widget.insert(tk.END, f"Response Type: {type(data)}\n\n")

                    # Check parameters structure
                    if isinstance(data, dict) and "parameters" in data:
                        params = data["parameters"]
                        text_widget.insert(tk.END, f"Parameters Type: {type(params)}\n")
                        if isinstance(params, list):
                            text_widget.insert(tk.END, f"Parameters is a LIST with {len(params)} items\n")
                            if params:
                                text_widget.insert(tk.END, f"First few parameters: {params[:5]}\n\n")
                        elif isinstance(params, dict):
                            text_widget.insert(tk.END, f"Parameters is a DICT with {len(params)} items\n")
                            if params:
                                keys = list(params.keys())[:5]
                                text_widget.insert(tk.END, f"First few parameter keys: {keys}\n\n")

                    # Show full response
                    text_widget.insert(tk.END, f"Response Content:\n{json.dumps(data, indent=2)}")
                except json.JSONDecodeError:
                    text_widget.insert(tk.END, f"Could not parse as JSON. Raw content:\n{response.text}")
            else:
                text_widget.insert(tk.END, f"Raw response:\n{response.text}")

        except Exception as e:
            text_widget.insert(tk.END, f"Error: {str(e)}\n\n")
            import traceback
            text_widget.insert(tk.END, traceback.format_exc())

        # Make the text widget read-only
        text_widget.configure(state="disabled")

    def set_status(self, message):
        """Update status bar with message"""
        self.status_message = message
        self.status_bar.config(text=message)
        self.root.update_idletasks()

    def load_datasets(self):
        """Fetch available datasets from the API"""
        self.set_status("Fetching available datasets...")
        self.dataset_listbox.delete(0, tk.END)

        try:
            response = requests.get(self.DATASETS_URL)
            if response.status_code == 200:
                # Store the dataset information
                data = response.json()

                # Check if the response is a dictionary as expected
                if isinstance(data, dict):
                    self.datasets = data

                    # Add datasets to listbox in sorted order
                    sorted_keys = sorted(self.datasets.keys())
                    for key in sorted_keys:
                        self.dataset_listbox.insert(tk.END, key)

                    self.set_status(f"Loaded {len(self.datasets)} datasets")
                else:
                    # Handle the case where the API returns a list or other data type
                    self.set_status("Error: Unexpected API response format")
                    self.debug_print(f"API Response Type: {type(data)}")
                    self.debug_print(f"API Response Content: {data[:1000] if isinstance(data, (list, str)) else data}")
            else:
                self.set_status(f"Error loading datasets: HTTP {response.status_code}")
        except Exception as e:
            self.set_status(f"Error: {str(e)}")
            import traceback
            traceback.print_exc()

    def on_dataset_select(self, event):
        """Handle dataset selection from listbox"""
        selection = self.dataset_listbox.curselection()
        if not selection:
            return

        index = selection[0]
        selected_key = self.dataset_listbox.get(index)
        self.selected_dataset = selected_key

        try:
            # Check if the datasets is a dictionary and contains the selected key
            if isinstance(self.datasets, dict) and selected_key in self.datasets:
                self.selected_dataset_info = self.datasets[selected_key]
                self.debug_print(f"Dataset info from API: {self.selected_dataset_info}")
            else:
                # If the datasets is not a dictionary or doesn't contain the key,
                # build the URL manually based on the key
                self.set_status(f"Info not found for {selected_key}, constructing URL manually...")
                dataset_url = self.get_dataset_url(selected_key)
                self.debug_print(f"Constructed URL: {dataset_url}")
                self.selected_dataset_info = {
                    "url": dataset_url,
                    "type": "unknown",
                    "mode": "unknown"
                }

            # Clear existing parameters and stations
            for widget in self.params_frame.winfo_children():
                widget.destroy()

            for widget in self.stations_frame.winfo_children():
                widget.destroy()

            # Reset selections
            self.selected_parameters = []
            self.selected_stations = []

            # Fetch metadata for the selected dataset
            self.fetch_metadata()
        except Exception as e:
            self.set_status(f"Error selecting dataset: {str(e)}")
            import traceback
            traceback.print_exc()

    def fetch_metadata(self):
        """Fetch metadata for the selected dataset"""
        if not self.selected_dataset:
            return

        self.set_status(f"Loading metadata for {self.selected_dataset}...")

        try:
            # Get the URL for metadata
            if isinstance(self.selected_dataset_info, dict) and 'url' in self.selected_dataset_info:
                base_url = self.selected_dataset_info['url']
            else:
                # Construct URL from the dataset key
                base_url = self.get_dataset_url(self.selected_dataset)

            url = f"{base_url}/metadata"
            self.set_status(f"Requesting metadata from: {url}")

            response = requests.get(url)

            if response.status_code == 200:
                try:
                    metadata = response.json()

                    # Debug output
                    if isinstance(metadata, dict):
                        self.debug_print(f"Metadata keys: {metadata.keys()}")
                    else:
                        self.debug_print(f"Metadata is not a dictionary but a {type(metadata)}")

                    self.debug_print(f"Metadata type: {type(metadata)}")

                    # Check parameters format to help with debugging
                    if isinstance(metadata, dict) and "parameters" in metadata:
                        params = metadata["parameters"]
                        self.debug_print(f"Parameters type: {type(params)}")
                        if isinstance(params, list):
                            self.debug_print(f"Parameters is a list with {len(params)} items")
                            if params and len(params) > 0:
                                self.debug_print(f"First parameter: {params[0]}")
                        elif isinstance(params, dict):
                            self.debug_print(f"Parameters is a dict with {len(params)} items")
                            if params and len(params) > 0:
                                first_key = next(iter(params))
                                self.debug_print(f"First parameter key: {first_key}, value: {params[first_key]}")

                    # Check stations format
                    if isinstance(metadata, dict) and "stations" in metadata:
                        stations = metadata["stations"]
                        self.debug_print(f"Stations type: {type(stations)}")
                        if isinstance(stations, list):
                            self.debug_print(f"Stations is a list with {len(stations)} items")
                            if stations and len(stations) > 0:
                                self.debug_print(f"First station: {stations[0]}")
                        elif isinstance(stations, dict):
                            self.debug_print(f"Stations is a dict with {len(stations)} items")
                            if stations and len(stations) > 0:
                                first_key = next(iter(stations))
                                self.debug_print(f"First station key: {first_key}, value: {stations[first_key]}")

                    # Populate parameters if available
                    if isinstance(metadata, dict) and "parameters" in metadata:
                        self.create_parameter_checkboxes(metadata["parameters"])
                    else:
                        self.set_status("No parameters found in metadata")

                    # Populate stations if available
                    if isinstance(metadata, dict) and "stations" in metadata:
                        self.create_station_checkboxes(metadata["stations"])
                    else:
                        self.set_status("No stations found in metadata")

                    if isinstance(metadata, dict):
                        self.set_status(f"Loaded metadata for {self.selected_dataset}")
                    else:
                        self.set_status(f"Metadata is not in the expected format")
                except json.JSONDecodeError:
                    self.set_status("Error: Could not parse metadata as JSON")
                    self.debug_print(f"Response content: {response.text[:1000]}")
            else:
                self.set_status(f"Error loading metadata: HTTP {response.status_code}")
                self.debug_print(f"Response content: {response.text[:1000]}")
        except Exception as e:
            self.set_status(f"Error: {str(e)}")
            import traceback
            traceback.print_exc()

    def create_parameter_checkboxes(self, parameters):
        """Create checkboxes for each parameter"""
        # Create a variable to store parameter state
        self.param_vars = {}

        # Handle different parameter formats - could be dict or list
        if isinstance(parameters, dict):
            # Dictionary format
            self.debug_print("Parameters are in dictionary format")
            param_items = []
            for param_id, param_info in parameters.items():
                param_items.append((param_id, param_info))
            sorted_params = sorted(param_items, key=lambda x: x[0])

            for param_id, param_info in sorted_params:
                # Create a variable for this parameter
                var = tk.BooleanVar()
                self.param_vars[param_id] = var

                # Create checkbox with tooltip
                frame = ttk.Frame(self.params_frame)
                frame.pack(fill=tk.X, padx=5, pady=1)

                # Add parameter checkbox
                check = ttk.Checkbutton(frame, text=param_id, variable=var,
                                      command=lambda p=param_id, v=var: self.toggle_parameter(p, v))
                check.pack(side=tk.LEFT)

                # Add description label if available
                if isinstance(param_info, dict) and "description" in param_info:
                    desc_label = ttk.Label(frame, text=f" - {param_info['description']}", wraplength=300)
                    desc_label.pack(side=tk.LEFT, fill=tk.X, expand=True)

        elif isinstance(parameters, list):
            # List format
            self.debug_print("Parameters are in list format")

            # Check if list contains dictionaries with parameter info
            if parameters and isinstance(parameters[0], dict):
                self.debug_print("List contains parameter dictionaries")

                # Extract parameter names and sort them
                param_items = []
                for param_dict in parameters:
                    # Get parameter name/id and other info
                    if "name" in param_dict:
                        param_id = param_dict["name"]
                        param_items.append((param_id, param_dict))

                # Sort by parameter name
                param_items.sort(key=lambda x: x[0])

                for param_id, param_info in param_items:
                    # Create a variable for this parameter
                    var = tk.BooleanVar()
                    self.param_vars[param_id] = var

                    # Create checkbox with tooltip
                    frame = ttk.Frame(self.params_frame)
                    frame.pack(fill=tk.X, padx=5, pady=1)

                    # Add parameter checkbox
                    display_text = param_id
                    # Add long name if available
                    if "long_name" in param_info:
                        display_text = f"{param_id} - {param_info['long_name']}"

                    check = ttk.Checkbutton(frame, text=display_text, variable=var,
                                         command=lambda p=param_id, v=var: self.toggle_parameter(p, v))
                    check.pack(side=tk.LEFT)

                    # Add description and unit if available
                    desc_text = ""
                    if "desc" in param_info:
                        desc_text = param_info["desc"]
                    if "unit" in param_info:
                        if desc_text:
                            desc_text += f" ({param_info['unit']})"
                        else:
                            desc_text = f"Unit: {param_info['unit']}"

                    if desc_text:
                        desc_label = ttk.Label(frame, text=f" - {desc_text}", wraplength=300)
                        desc_label.pack(side=tk.LEFT, fill=tk.X, expand=True)
            else:
                # List of simple values
                sorted_params = sorted(parameters)

                for param_id in sorted_params:
                    # Create a variable for this parameter
                    var = tk.BooleanVar()
                    self.param_vars[param_id] = var

                    # Create checkbox
                    frame = ttk.Frame(self.params_frame)
                    frame.pack(fill=tk.X, padx=5, pady=1)

                    # Add parameter checkbox
                    check = ttk.Checkbutton(frame, text=param_id, variable=var,
                                         command=lambda p=param_id, v=var: self.toggle_parameter(p, v))
                    check.pack(side=tk.LEFT)

        else:
            # Unknown format
            self.debug_print(f"Unknown parameters format: {type(parameters)}")
            error_label = ttk.Label(self.params_frame,
                                   text=f"Error: Unknown parameters format ({type(parameters)})",
                                   foreground="red")
            error_label.pack(padx=5, pady=5)

    def create_station_checkboxes(self, stations):
        """Create checkboxes for each station"""
        # Create variables to store station states
        self.station_vars = {}

        # Handle different station formats - could be dict or list
        if isinstance(stations, dict):
            # Dictionary format
            self.debug_print("Stations are in dictionary format")
            # Sort stations by ID or name for easier navigation
            sorted_stations = sorted(stations.items(), key=lambda x: x[0])

            for i, (station_id, station_info) in enumerate(sorted_stations):
                # Create a variable for this station
                var = tk.BooleanVar()
                self.station_vars[station_id] = var

                # Get station name if available
                name = station_info.get("name", f"Station {station_id}")

                # Create checkbox with tooltip
                frame = ttk.Frame(self.stations_frame)
                frame.pack(fill=tk.X, padx=5, pady=1)

                # Add station checkbox
                check = ttk.Checkbutton(frame, text=f"{name} (ID: {station_id})", variable=var,
                                      command=lambda s=station_id, v=var: self.toggle_station(s, v))
                check.pack(side=tk.LEFT, fill=tk.X, expand=True)

        elif isinstance(stations, list):
            # List format
            self.debug_print("Stations are in list format")

            # Check if list contains dictionaries with station info
            if stations and isinstance(stations[0], dict):
                self.debug_print("List contains station dictionaries")

                # Sort stations by ID or name for easier navigation
                if "id" in stations[0]:
                    # Sort by ID if available
                    sorted_stations = sorted(stations, key=lambda x: x.get("id", ""))
                else:
                    # Otherwise sort by name
                    sorted_stations = sorted(stations, key=lambda x: x.get("name", ""))

                for station_dict in sorted_stations:
                    # Get station ID
                    station_id = station_dict.get("id", "")
                    if not station_id:
                        continue  # Skip stations without ID

                    # Create a variable for this station
                    var = tk.BooleanVar()
                    self.station_vars[station_id] = var

                    # Get station name if available
                    name = station_dict.get("name", f"Station {station_id}")

                    # Create checkbox frame
                    frame = ttk.Frame(self.stations_frame)
                    frame.pack(fill=tk.X, padx=5, pady=1)

                    # Add station checkbox
                    check = ttk.Checkbutton(frame, text=f"{name} (ID: {station_id})", variable=var,
                                          command=lambda s=station_id, v=var: self.toggle_station(s, v))
                    check.pack(side=tk.LEFT, fill=tk.X, expand=True)
            else:
                # Simple list of station IDs
                sorted_stations = sorted(stations)

                for station_id in sorted_stations:
                    # Create a variable for this station
                    var = tk.BooleanVar()
                    self.station_vars[station_id] = var

                    # Create checkbox
                    frame = ttk.Frame(self.stations_frame)
                    frame.pack(fill=tk.X, padx=5, pady=1)

                    # Add station checkbox
                    check = ttk.Checkbutton(frame, text=f"Station {station_id}", variable=var,
                                          command=lambda s=station_id, v=var: self.toggle_station(s, v))
                    check.pack(side=tk.LEFT, fill=tk.X, expand=True)

        else:
            # Unknown format
            self.debug_print(f"Unknown stations format: {type(stations)}")
            error_label = ttk.Label(self.stations_frame,
                                   text=f"Error: Unknown stations format ({type(stations)})",
                                   foreground="red")
            error_label.pack(padx=5, pady=5)

    def toggle_parameter(self, param_id, var):
        """Toggle a parameter selection"""
        if var.get():
            if param_id not in self.selected_parameters:
                self.selected_parameters.append(param_id)
        else:
            if param_id in self.selected_parameters:
                self.selected_parameters.remove(param_id)

    def toggle_station(self, station_id, var):
        """Toggle a station selection"""
        if var.get():
            if station_id not in self.selected_stations:
                self.selected_stations.append(station_id)
        else:
            if station_id in self.selected_stations:
                self.selected_stations.remove(station_id)

    def download_data(self):
        """Download data for the selected parameters and stations"""
        if not self.selected_dataset:
            self.set_status("Error: No dataset selected")
            return

        if not self.selected_parameters:
            self.set_status("Error: No parameters selected")
            return

        if not self.selected_stations:
            self.set_status("Error: No stations selected")
            return

        # Prepare query parameters
        params = {
            "parameters": ",".join(self.selected_parameters),
            "station_ids": ",".join(self.selected_stations),
            "output_format": self.format_combo.get()
        }

        # Add date range if specified
        start_date = self.start_date_entry.get()
        if start_date and start_date != "YYYY-MM-DD":
            try:
                # Validate date format
                datetime.strptime(start_date, "%Y-%m-%d")
                params["start"] = start_date
            except ValueError:
                self.set_status("Error: Invalid start date format. Use YYYY-MM-DD.")
                return

        end_date = self.end_date_entry.get()
        if end_date and end_date != "YYYY-MM-DD":
            try:
                # Validate date format
                datetime.strptime(end_date, "%Y-%m-%d")
                params["end"] = end_date
            except ValueError:
                self.set_status("Error: Invalid end date format. Use YYYY-MM-DD.")
                return

        # Get the API URL
        if isinstance(self.selected_dataset_info, dict) and 'url' in self.selected_dataset_info:
            url = self.selected_dataset_info['url']
        else:
            url = self.get_dataset_url(self.selected_dataset)

        # Download data
        self.set_status(f"Downloading data from {url}...")
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
                    self.debug_print(f"Downloaded JSON data ({len(str(self.result_data))} characters)")
                elif 'csv' in content_type:
                    # Parse CSV data
                    csv_data = pd.read_csv(io.StringIO(response.text))
                    self.result_data = csv_data
                    self.debug_print(f"Downloaded CSV data ({len(response.text)} characters, {len(csv_data)} rows)")
                else:
                    # Store raw data
                    self.result_data = response.text
                    self.debug_print(f"Downloaded raw data ({len(response.text)} characters)")

                self.set_status("Data downloaded successfully")
            else:
                self.set_status(f"Error downloading data: HTTP {response.status_code}")
                self.debug_print(f"Error response: {response.text[:1000]}")
        except Exception as e:
            self.set_status(f"Error: {str(e)}")
            import traceback
            traceback.print_exc()

    def save_data(self):
        """Save downloaded data to a file"""
        if not self.result_data:
            self.set_status("Error: No data to save")
            return

        # Get file format
        format_type = self.format_combo.get()

        # Create file extension
        file_extension = format_type

        # Create default filename
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        default_filename = f"geosphere_data_{timestamp}.{file_extension}"

        # Ask for save location
        file_path = filedialog.asksaveasfilename(
            defaultextension=f".{file_extension}",
            filetypes=[
                (f"{format_type.upper()} files", f"*.{file_extension}"),
                ("All files", "*.*")
            ],
            initialfile=default_filename
        )

        if not file_path:
            return  # User cancelled

        try:
            # Save based on data type and format
            if format_type == "csv":
                if isinstance(self.result_data, pd.DataFrame):
                    self.result_data.to_csv(file_path, index=False)
                elif isinstance(self.result_data, dict) and "features" in self.result_data:
                    # Convert GeoJSON to DataFrame
                    features_data = []
                    for feature in self.result_data["features"]:
                        if "properties" in feature:
                            features_data.append(feature["properties"])

                    if features_data:
                        pd.DataFrame(features_data).to_csv(file_path, index=False)
                    else:
                        with open(file_path, 'w') as f:
                            f.write(str(self.result_data))
                else:
                    # Try generic conversion to CSV
                    try:
                        pd.DataFrame(self.result_data).to_csv(file_path, index=False)
                    except:
                        with open(file_path, 'w') as f:
                            f.write(str(self.result_data))
            elif format_type == "geojson":
                if isinstance(self.result_data, dict):
                    with open(file_path, 'w') as f:
                        json.dump(self.result_data, f, indent=4)
                else:
                    # Convert to JSON if not already
                    with open(file_path, 'w') as f:
                        json.dump({"data": self.result_data}, f, indent=4)
            else:
                # Save as raw text
                with open(file_path, 'w') as f:
                    f.write(str(self.result_data))

            self.set_status(f"Data saved to {file_path}")
        except Exception as e:
            self.set_status(f"Error saving data: {str(e)}")
            import traceback
            traceback.print_exc()

    def start_bulk_download(self):
        """Start bulk download of all parameters for selected stations"""
        if not self.selected_dataset:
            self.set_status("Error: No dataset selected")
            return

        if not self.selected_stations:
            self.set_status("Error: No stations selected for bulk download")
            return

        # Ask for output directory
        output_dir = filedialog.askdirectory(title="Select Output Directory for Bulk Download")
        if not output_dir:
            return  # User cancelled

        # Get date range
        start_date = None
        end_date = None

        start_date_text = self.start_date_entry.get()
        if start_date_text and start_date_text != "YYYY-MM-DD":
            try:
                start_date = datetime.strptime(start_date_text, "%Y-%m-%d").strftime("%Y-%m-%d")
            except ValueError:
                self.set_status("Error: Invalid start date format. Use YYYY-MM-DD.")
                return

        end_date_text = self.end_date_entry.get()
        if end_date_text and end_date_text != "YYYY-MM-DD":
            try:
                end_date = datetime.strptime(end_date_text, "%Y-%m-%d").strftime("%Y-%m-%d")
            except ValueError:
                self.set_status("Error: Invalid end date format. Use YYYY-MM-DD.")
                return

        # Get output format
        format_type = self.format_combo.get()

        # Create and show progress dialog
        self.create_progress_dialog(output_dir, start_date, end_date, format_type)

    def create_progress_dialog(self, output_dir, start_date, end_date, format_type):
        """Create a progress dialog for bulk download"""
        progress_window = tk.Toplevel(self.root)
        progress_window.title("Bulk Download Progress")
        progress_window.geometry("400x200")
        progress_window.transient(self.root)
        progress_window.grab_set()

        # Configure layout
        progress_frame = ttk.Frame(progress_window, padding="10")
        progress_frame.pack(fill=tk.BOTH, expand=True)

        # Status label
        status_label = ttk.Label(progress_frame, text="Starting bulk download...")
        status_label.pack(pady=10)

        # Progress bar
        progress_bar = ttk.Progressbar(progress_frame, mode='determinate')
        progress_bar.pack(fill=tk.X, pady=10)

        # Progress text
        progress_text = ttk.Label(progress_frame, text="0 of 0 stations completed")
        progress_text.pack(pady=5)

        # Cancel button
        cancel_button = ttk.Button(progress_frame, text="Cancel",
                                 command=lambda: self.cancel_bulk_download(progress_window))
        cancel_button.pack(pady=10)

        # Set initial state
        self.is_bulk_downloading = True
        self.bulk_download_cancel = False

        # Start download in a separate thread
        download_thread = threading.Thread(
            target=self.bulk_download_thread,
            args=(output_dir, start_date, end_date, format_type,
                 progress_window, progress_bar, status_label, progress_text)
        )
        download_thread.daemon = True
        download_thread.start()

    def cancel_bulk_download(self, progress_window):
        """Cancel the bulk download process"""
        self.bulk_download_cancel = True
        self.set_status("Bulk download cancelled by user")
        progress_window.destroy()

    def bulk_download_thread(self, output_dir, start_date, end_date, format_type,
                           progress_window, progress_bar, status_label, progress_text):
        """Run bulk download in a separate thread"""
        try:
            # Fetch metadata to get all parameters
            if isinstance(self.selected_dataset_info, dict) and 'url' in self.selected_dataset_info:
                base_url = self.selected_dataset_info['url']
            else:
                base_url = self.get_dataset_url(self.selected_dataset)

            url = f"{base_url}/metadata"
            self.debug_print(f"Fetching metadata from: {url}")

            response = requests.get(url)

            if response.status_code != 200:
                self.set_status(f"Error loading metadata: HTTP {response.status_code}")
                progress_window.destroy()
                return

            metadata = response.json()
            self.debug_print(f"Metadata type: {type(metadata)}")

            # Get all parameter names
            if "parameters" not in metadata:
                self.set_status("Error: No parameters available in metadata")
                progress_window.destroy()
                return

            # Handle both dictionary and list formats for parameters
            parameters = metadata["parameters"]
            if isinstance(parameters, dict):
                all_parameters = list(parameters.keys())
                self.debug_print(f"Parameters in dictionary format, found {len(all_parameters)} parameters")
            elif isinstance(parameters, list):
                # Check if the list contains dictionaries with parameter info
                if parameters and isinstance(parameters[0], dict):
                    self.debug_print("Parameters are dictionaries in a list")
                    all_parameters = []
                    for param_dict in parameters:
                        if "name" in param_dict:
                            all_parameters.append(param_dict["name"])
                    self.debug_print(f"Extracted {len(all_parameters)} parameter names from parameter dictionaries")
                else:
                    all_parameters = parameters
                    self.debug_print(f"Parameters in list format, found {len(all_parameters)} parameters")
            else:
                self.set_status(f"Error: Unexpected parameters format: {type(parameters)}")
                progress_window.destroy()
                return

            # Create output directory if it doesn't exist
            if not os.path.exists(output_dir):
                os.makedirs(output_dir)

            # For each station, download all parameters
            total_stations = len(self.selected_stations)
            successful_downloads = 0

            # Configure progress bar
            progress_bar["maximum"] = total_stations

            for i, station_id in enumerate(self.selected_stations):
                # Check if download was cancelled
                if self.bulk_download_cancel:
                    break

                # Update status and progress
                status_text = f"Processing station {station_id} ({i+1} of {total_stations})"
                progress_text["text"] = f"{successful_downloads} of {total_stations} stations completed"

                # Update UI in main thread
                self.root.after(0, lambda t=status_text: status_label.config(text=t))
                self.root.after(0, lambda v=i: progress_bar.config(value=v))

                # Prepare query parameters
                params = {
                    "station_ids": station_id,
                    "parameters": ",".join(all_parameters),
                    "output_format": format_type
                }

                # Add date range if specified
                if start_date:
                    params["start"] = start_date

                if end_date:
                    params["end"] = end_date

                # Download data
                try:
                    download_url = base_url
                    self.debug_print(f"Downloading from: {download_url} with params: {params}")
                    response = requests.get(download_url, params=params)

                    if response.status_code == 200:
                        # Create filename
                        filename = f"station_{station_id}_data.{format_type}"
                        file_path = os.path.join(output_dir, filename)

                        # Save data based on format
                        if format_type == "csv":
                            with open(file_path, 'w', newline='', encoding='utf-8') as f:
                                f.write(response.text)
                        elif format_type == "geojson":
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(response.text)
                        else:
                            # Save as raw text
                            with open(file_path, 'wb') as f:
                                f.write(response.content)

                        successful_downloads += 1
                        self.debug_print(f"Successfully saved {file_path}")
                    else:
                        self.debug_print(f"Error downloading station {station_id}: HTTP {response.status_code}")
                        self.debug_print(f"Response: {response.text[:500]}")
                except Exception as e:
                    self.set_status(f"Error downloading station {station_id}: {str(e)}")
                    self.debug_print(f"Exception: {str(e)}")
                    import traceback
                    self.debug_print(traceback.format_exc())

            # Final update for progress
            if not self.bulk_download_cancel:
                self.root.after(0, lambda: progress_bar.config(value=total_stations))
                self.root.after(0, lambda: progress_text.config(
                    text=f"{successful_downloads} of {total_stations} stations completed"))
                self.root.after(0, lambda: status_label.config(
                    text="Bulk download completed!"))

            # Set final status message
            if self.bulk_download_cancel:
                self.set_status("Bulk download cancelled by user")
            else:
                self.set_status(f"Bulk download completed. Successfully downloaded data for {successful_downloads} out of {total_stations} stations.")

            # Close progress window after a delay if not cancelled
            if not self.bulk_download_cancel:
                self.root.after(3000, progress_window.destroy)

        except Exception as e:
            self.set_status(f"Error during bulk download: {str(e)}")
            self.debug_print(f"Exception in bulk download: {str(e)}")
            import traceback
            self.debug_print(traceback.format_exc())
            self.root.after(0, progress_window.destroy)

        finally:
            self.is_bulk_downloading = False

            for i, station_id in enumerate(self.selected_stations):
                # Check if download was cancelled
                if self.bulk_download_cancel:
                    break

                # Update status and progress
                status_text = f"Processing station {station_id} ({i+1} of {total_stations})"
                progress_text["text"] = f"{successful_downloads} of {total_stations} stations completed"

                # Update UI in main thread
                self.root.after(0, lambda t=status_text: status_label.config(text=t))
                self.root.after(0, lambda v=i: progress_bar.config(value=v))

                # Prepare query parameters
                params = {
                    "station_ids": station_id,
                    "parameters": ",".join(all_parameters),
                    "output_format": format_type
                }

                # Add date range if specified
                if start_date:
                    params["start"] = start_date

                if end_date:
                    params["end"] = end_date

                # Download data
                try:
                    download_url = base_url
                    self.debug_print(f"Downloading from: {download_url} with params: {params}")
                    response = requests.get(download_url, params=params)

                    if response.status_code == 200:
                        # Create filename
                        filename = f"station_{station_id}_data.{format_type}"
                        file_path = os.path.join(output_dir, filename)

                        # Save data based on format
                        if format_type == "csv":
                            with open(file_path, 'w', newline='', encoding='utf-8') as f:
                                f.write(response.text)
                        elif format_type == "geojson":
                            with open(file_path, 'w', encoding='utf-8') as f:
                                f.write(response.text)
                        else:
                            # Save as raw text
                            with open(file_path, 'wb') as f:
                                f.write(response.content)

                        successful_downloads += 1
                        self.debug_print(f"Successfully saved {file_path}")
                    else:
                        self.debug_print(f"Error downloading station {station_id}: HTTP {response.status_code}")
                        self.debug_print(f"Response: {response.text[:500]}")
                except Exception as e:
                    self.set_status(f"Error downloading station {station_id}: {str(e)}")
                    self.debug_print(f"Exception: {str(e)}")
                    import traceback
                    self.debug_print(traceback.format_exc())

            # Final update for progress
            if not self.bulk_download_cancel:
                self.root.after(0, lambda: progress_bar.config(value=total_stations))
                self.root.after(0, lambda: progress_text.config(
                    text=f"{successful_downloads} of {total_stations} stations completed"))
                self.root.after(0, lambda: status_label.config(
                    text="Bulk download completed!"))

            # Set final status message
            if self.bulk_download_cancel:
                self.set_status("Bulk download cancelled by user")
            else:
                self.set_status(f"Bulk download completed. Successfully downloaded data for {successful_downloads} out of {total_stations} stations.")

            # Close progress window after a delay if not cancelled
            if not self.bulk_download_cancel:
                self.root.after(3000, progress_window.destroy)

        except Exception as e:
            self.set_status(f"Error during bulk download: {str(e)}")
            self.debug_print(f"Exception in bulk download: {str(e)}")
            import traceback
            self.debug_print(traceback.format_exc())
            self.root.after(0, progress_window.destroy)

        finally:
            self.is_bulk_downloading = False


if __name__ == "__main__":
    root = tk.Tk()
    app = GeosphereAPIApp(root)
    root.mainloop()
