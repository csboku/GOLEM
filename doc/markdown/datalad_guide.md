# DataLad Guide and Cheat Sheet

## What is DataLad?

DataLad is a data management tool that provides a unified interface for working with data across different storage systems. It combines Git (for metadata and small files) with git-annex (for large files) to create a powerful version control system for datasets of any size.

**Key Benefits:**
- Version control for large datasets
- Reproducible data analysis pipelines
- Seamless data sharing and collaboration
- Works with remote storage (cloud, clusters, etc.)
- Perfect for scientific workflows with large data files

## Installation

### Via conda (recommended)
```bash
conda install -c conda-forge datalad
```

### Via pip
```bash
pip install datalad
```

### Additional components (optional but useful)
```bash
# For additional functionality
conda install -c conda-forge git-annex
pip install datalad[full]
```

## Core Concepts

### Dataset
A DataLad dataset is a Git repository enhanced with git-annex capabilities. It can contain:
- Small files (tracked by Git)
- Large files (tracked by git-annex)
- Subdatasets (nested datasets)

### States of Files
- **Available**: File content is present locally
- **Unavailable**: Only metadata is present, content needs to be retrieved
- **Modified**: File has been changed since last save

## Basic Workflow

### 1. Creating and Working with Datasets

```bash
# Create a new dataset
datalad create my_dataset
cd my_dataset

# Create with a specific location
datalad create --description "My research data" /path/to/dataset

# Clone an existing dataset
datalad clone https://github.com/user/dataset.git
```

### 2. Adding Data

```bash
# Add files to the dataset
datalad save file.txt
datalad save "Added new data file" file.txt  # with message

# Add multiple files
datalad save *.nc  # All NetCDF files
datalad save -m "Added model output" output/

# Add and save in one step
echo "data" > newfile.txt
datalad save -m "Added newfile" newfile.txt
```

### 3. Getting Data

```bash
# Get file content (download if needed)
datalad get data/large_file.nc
datalad get data/  # Get all files in directory

# Get with specific subdataset
datalad get -s subdataset_name file.txt
```

### 4. Data Status and Information

```bash
# Check status of dataset
datalad status

# Show information about files
datalad ls -L  # List files with detailed info
datalad ls --json  # JSON output

# Check what needs to be retrieved
datalad status --annex
```

## Essential Commands Reference

### Dataset Management
```bash
datalad create [--description "text"] <path>     # Create dataset
datalad clone <url> [<path>]                     # Clone dataset
datalad install <path/url>                       # Install subdataset
datalad uninstall <path>                         # Uninstall subdataset
```

### Data Operations
```bash
datalad save [-m "message"] [<files>]            # Save changes
datalad get [<files>]                            # Retrieve file content
datalad drop [<files>]                           # Remove content (keep metadata)
datalad status [<files>]                         # Show status
datalad diff [<files>]                           # Show differences
```

### Remote Operations
```bash
datalad siblings                                 # List remotes
datalad siblings add -d . --name <name> --url <url>  # Add remote
datalad push --to <remote>                       # Push to remote
datalad update [--merge]                         # Update from remote
```

### Metadata and Search
```bash
datalad metadata [<files>]                       # Show metadata
datalad search [<query>]                         # Search datasets
datalad ls [-L] [<path>]                         # List contents
```

## Working with Large Files (Atmospheric Data)

### Efficient Data Handling
```bash
# Add large NetCDF files without copying content immediately
datalad save --to-git large_model_output.nc

# Get only specific files you need
datalad get data/2023/january/*.nc

# Work with partial datasets
datalad get -J 4 data/  # Parallel download (4 jobs)
```

### Configuring File Types
```bash
# Configure git-annex for specific file types
git config annex.largefiles "largerthan=10MB or include=*.nc or include=*.hdf5"
```

## Subdatasets for Modular Data

```bash
# Create subdataset for different data types
datalad create -d . raw_data
datalad create -d . processed_data
datalad create -d . model_output

# Install specific subdatasets when needed
datalad get -s raw_data
```

## Integration with Research Workflows

### With WRFChem Workflows
```bash
# Create project structure
datalad create wrfchem_project
cd wrfchem_project

# Create subdatasets for different components
datalad create -d . input_data
datalad create -d . namelist_configs  
datalad create -d . output_data
datalad create -d . analysis_scripts

# Save configuration files
datalad save -m "Added WRF namelist" namelist_configs/namelist.input

# Save large output files
datalad save -m "Model run for case study" output_data/wrfout_d01_*
```

### With Python/R/Julia Scripts
```bash
# Save analysis scripts
datalad save -m "Added emission analysis script" scripts/analyze_emissions.py
datalad save -m "Updated plotting functions" scripts/plotting.R
datalad save -m "Added data processing module" scripts/process_data.jl

# Run and save results
python scripts/analyze_emissions.py
datalad save -m "Analysis results for Q1 2024" results/
```

## Quick Cheat Sheet

| Command | Description |
|---------|-------------|
| `datalad create <name>` | Create new dataset |
| `datalad clone <url>` | Clone existing dataset |
| `datalad save -m "msg" <files>` | Save changes with message |
| `datalad get <files>` | Download file content |
| `datalad drop <files>` | Remove content, keep metadata |
| `datalad status` | Show dataset status |
| `datalad push` | Push changes to remote |
| `datalad update` | Update from remote |
| `datalad ls -L` | List files with details |
| `datalad siblings` | Show remotes |

## Common Use Cases for Atmospheric Chemistry

### 1. Managing Model Input Data
```bash
# Create dataset for meteorological input
datalad create meteo_inputs
datalad save -m "Added ECMWF reanalysis data" *.grib

# Share with collaborators
datalad siblings add --name origin --url git@server:meteo_inputs.git
datalad push --to origin
```

### 2. Tracking Model Configurations
```bash
# Version control your namelists and configurations
datalad save -m "Updated chemistry mechanism" namelist.input.chem
datalad save -m "Modified domain configuration" namelist.wps
```

### 3. Managing Large Output Files
```bash
# Save model outputs efficiently
datalad save -m "48h forecast run" wrfout_d01_2024-01-*

# Share specific results without full dataset
datalad get analysis_plots/
datalad drop wrfout_d01_*  # Remove large files, keep metadata
```

## Troubleshooting

### Common Issues
```bash
# Fix locked files
git annex unlock <file>

# Repair dataset
datalad wtf  # "What's the fuss" - diagnostic info
git annex fsck  # Check dataset integrity

# Reset file state
git annex drop --force <file>
datalad get <file>
```

### Performance Tips
- Use `datalad get -J <n>` for parallel downloads
- Configure `annex.largefiles` appropriately
- Use `datalad drop` to free up space
- Consider using `--recursive` for subdatasets

## Best Practices for Research

1. **Organize by data type**: Use subdatasets for raw data, processed data, and results
2. **Descriptive commit messages**: Always use meaningful messages with `datalad save`
3. **Regular saves**: Save work frequently, especially before major changes
4. **Clean metadata**: Use consistent naming conventions
5. **Document workflows**: Include README files and analysis scripts in version control
6. **Backup strategy**: Set up remotes for important datasets

This workflow is particularly powerful for atmospheric chemistry research where you need to manage large model outputs, multiple data sources, and ensure reproducibility across different computing environments.