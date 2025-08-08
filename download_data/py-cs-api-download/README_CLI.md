# GeoSphere Austria Dataset API CLI

A command-line interface for downloading meteorological and climatological data from the GeoSphere Austria Dataset API.

## Features

- Browse available datasets from the GeoSphere Austria API
- Select parameters and stations from these datasets
- Download data with date range filtering
- Save data in CSV or GeoJSON formats
- Bulk download functionality for multiple parameters
- Interactive and non-interactive modes

## Requirements

- Python 3.6+
- Required packages: `requests`, `pandas`

## Installation

1. Clone this repository or download the script
2. Install required packages:

```bash
pip install requests pandas
```

3. Make the script executable:

```bash
chmod +x cs-geo-api-cli.py
```

## Usage

### Interactive Mode

Run the script in interactive mode to explore datasets through a text-based interface:

```bash
./cs-geo-api-cli.py --interactive
```

In interactive mode, you can use the following commands:

- `help` or `?` - Show help message
- `datasets` - List available datasets
- `select <dataset_id|index>` - Select a dataset by ID or index
- `parameters` - List parameters for the selected dataset
- `stations` - List stations for the selected dataset
- `selectparam <idx1 idx2 ... | id1 id2 ...>` - Select parameters
- `selectstation <idx1 idx2 ... | id1 id2 ...>` - Select stations
- `download [options]` - Download data for selected parameters and stations
  - `--start YYYY-MM-DD` - Start date for the data
  - `--end YYYY-MM-DD` - End date for the data
  - `--format csv|geojson` - Output format (default: csv)
  - `--output FILE` - Save output to file
- `bulkdownload [options]` - Download each parameter in separate files
  - `--start YYYY-MM-DD` - Start date for the data
  - `--end YYYY-MM-DD` - End date for the data
  - `--format csv|geojson` - Output format (default: csv)
  - `--output-dir DIRECTORY` - Directory to save output files
  - `--workers N` - Maximum parallel downloads (default: 3)
- `test` - Test API connection
- `debug [on|off]` - Show or set debug mode
- `quit`, `exit`, or `q` - Exit the application

### Non-Interactive Mode

You can also run the script in non-interactive mode for scripting or automation:

```bash
./cs-geo-api-cli.py --dataset <dataset_id> --parameters <param1,param2> --stations <station1,station2> --output <output_file>
```

Available arguments:

- `--debug` - Enable debug output
- `--dataset` - Dataset ID
- `--parameters` - Comma-separated list of parameter IDs
- `--stations` - Comma-separated list of station IDs
- `--start-date` - Start date (YYYY-MM-DD)
- `--end-date` - End date (YYYY-MM-DD)
- `--format` - Output format ('csv' or 'geojson', default: 'csv')
- `--output` - Output file
- `--bulk` - Perform bulk download
- `--output-dir` - Output directory for bulk download
- `--workers` - Maximum parallel workers for bulk download (default: 3)

## Examples

### Interactive Mode

```bash
./cs-geo-api-cli.py --interactive
```

### Download Data with Simple Options

```bash
./cs-geo-api-cli.py --dataset tawes-v1-10min --parameters t --stations 11035 --output temperature_data.csv
```

### Download Data with Date Range

```bash
./cs-geo-api-cli.py --dataset tawes-v1-10min --parameters t,rf --stations 11035,11036 --start-date 2023-01-01 --end-date 2023-01-07 --output weather_data.csv
```

### Bulk Download

```bash
./cs-geo-api-cli.py --dataset tawes-v1-10min --parameters t,rf,p --stations 11035,11036 --start-date 2023-01-01 --end-date 2023-01-07 --bulk --output-dir ./data
```

## Notes

- The API might have rate limits, so use bulk downloads with care
- Large data requests might take significant time to complete
- For very large datasets, consider using date ranges to split the download into smaller chunks

## License

[MIT License](LICENSE)