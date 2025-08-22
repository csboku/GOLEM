# Geosphere Austria Dataset API GUI

This application provides a graphical user interface for downloading meteorological and climatological data from the Geosphere Austria Dataset API. It's designed specifically for atmospheric chemistry researchers and others who need to access Austrian weather and climate data.

## Features

- Browse available datasets from Geosphere Austria
- View and select stations and parameters
- Set date ranges for historical data
- Choose output format (CSV or GeoJSON)
- Download and save data to local files
- Bulk download all parameters for selected stations in a specified timeframe

## Requirements

- Python 3.6 or newer
- Required packages:
  - requests
  - pandas
  - tkinter (usually included with Python)

## Installation

1. Make sure Python is installed on your system
2. Install required packages:

```bash
pip install requests pandas
```

3. Save the `geosphere_app.py` file to your local system

## Usage

1. Run the application:

```bash
python geosphere_app.py
```

2. Click "Load Datasets" to retrieve the list of available datasets
3. Select a dataset from the list to view its available parameters and stations
4. Check the parameters and stations you want to include
5. Optionally set a date range (format: YYYY-MM-DD)
6. Select your preferred output format (CSV or GeoJSON)
7. Click "Download Data" to retrieve the data
8. Click "Save Data to File" to save the downloaded data to your local system

### Bulk Download Feature

The bulk download feature allows you to download all available parameters for selected stations in a specific timeframe:

1. Select a dataset from the list
2. Check the stations you want to download data for (you can select multiple stations)
3. Set the date range (optional)
4. Select your preferred output format
5. Click "Bulk Download All Parameters"
6. Choose a directory to save the downloaded files
7. A progress dialog will appear showing the download progress

The files will be saved in the format `station_[ID]_data.[format]` in your selected directory
