#!/bin/bash

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Change to script directory
cd "$SCRIPT_DIR"

# Check if virtual environment exists and use it if so
if [ -d "venv" ]; then
    source venv/bin/activate
fi

# Run the application
python netcdf_viewer.py
