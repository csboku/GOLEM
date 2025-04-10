# NetCDF Viewer

A fast and powerful application for visualizing NetCDF data files, built with Python and PySide6.

## Features

- Fast and responsive UI built with Qt (PySide6)
- Works with Wayland and X11 display servers
- Visualize 1D, 2D, and 3D+ NetCDF data
- Browse variables and dimensions in NetCDF files
- Display metadata and attributes
- Save plots as PNG or PDF
- Cross-platform (Linux, macOS, Windows)

## Directory Structure

```
trurl/
├── python/         # Python implementation
│   ├── netcdf_viewer.py        # Main application
│   ├── requirements.txt        # Python dependencies
│   ├── setup.sh                # Setup script
│   ├── run.sh                  # Run script
│   └── build.sh                # Build script for standalone executable
├── dist/           # Compiled executables (created when built)
├── archive/        # Archived code
│   ├── julia/      # Original Julia implementation
│   └── experiments/ # Experimental implementations
├── assets/         # Static resources
└── netcdf-viewer   # Symbolic link to run script
```

## Installation

### Using the Python Implementation

1. Ensure Python 3.8+ is installed
2. Run the setup script to create a virtual environment and install dependencies:
   ```
   ./python/setup.sh
   ```

### Building Standalone Executable

To build a standalone executable that doesn't require Python to be installed:

```
./python/build.sh
```

This will create an executable in the `dist/` directory.

## Usage

### Running from Source

```
./netcdf-viewer
```

or

```
./python/run.sh
```

### Running the Standalone Executable

After building:

```
./dist/NetCDFViewer
```

## Using the NetCDF Viewer

1. Click "Open NetCDF File" to load a NetCDF file
2. Select a variable from the dropdown menu to visualize it
3. For 3D+ data, use the dimension selectors to choose which slice to view
4. The metadata panel shows detailed information about the file and variables
5. Click "Save Plot" to export the current visualization as PNG or PDF

## Requirements

- Python 3.8+
- The following Python packages (installed automatically by setup.sh):
  - PySide6
  - xarray
  - netCDF4
  - matplotlib
  - numpy
  - PyInstaller (for building executables)

## Executable Distribution

The standalone executable created with `build.sh` can be distributed to users who don't have Python installed. It includes all necessary dependencies.