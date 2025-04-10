#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
PARENT_DIR="$( dirname "$SCRIPT_DIR" )"

# Change to script directory
cd "$SCRIPT_DIR"

# Check if virtual environment exists and use it
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo "Virtual environment not found. Please run setup.sh first."
    exit 1
fi

# Create dist directory if it doesn't exist
mkdir -p "$PARENT_DIR/dist"

# Build standalone executable
echo "Building executable with PyInstaller..."
pyinstaller --onefile \
    --windowed \
    --name "NetCDFViewer" \
    --add-data "venv/lib/python*/site-packages/xarray:xarray" \
    --distpath "$PARENT_DIR/dist" \
    netcdf_viewer.py

echo "Build complete. Executable is in the dist directory."