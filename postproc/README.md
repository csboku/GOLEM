# WRF-Chem Postprocessing Tools

This directory contains tools for postprocessing WRF-Chem model output.

## WRF Variable Extraction

The `wrfchem_extract_par.py` script extracts variables from WRF-Chem output files at specific heights and at ground level, using parallel processing for improved performance.

### Usage Examples

#### Using a Configuration File

Create a YAML configuration file (e.g., `config.yaml`):

```yaml
# WRF-Chem Extraction Configuration
input:
  folder: "/path/to/wrfout/files"  # Directory containing wrfout files to process
  pattern: "wrfout_d01_*"          # File pattern to match (glob pattern)

output:
  folder: "/path/to/output"        # Directory for output files
  prefix: "extracted_"             # Prefix for output files

# Variables to extract
variables:
  - "O3"      # Ozone 
  - "PM2_5_DRY"  # PM2.5
  - "no"      # Nitric oxide
  - "no2"     # Nitrogen dioxide
  - "co"      # Carbon monoxide

# Heights for extraction (in meters above ground level)
heights:
  - 10    # 10 meters
  - 100   # 100 meters
  - 1000  # 1 kilometer

# Processing options
options:
  include_surface: true            # Whether to include surface level values
  processes: null                  # Number of processes (null = auto)
  process_files_parallel: true     # Process multiple files in parallel
  max_parallel_files: 2            # Maximum number of files to process in parallel
```

Then run the script with:

```bash
python wrfchem_extract_par.py --config config.yaml
```

#### Command Line Arguments

For a single file:

```bash
python wrfchem_extract_par.py --wrfout-file /path/to/wrfout_d01_2020-01-01_00:00:00 \
  --vars O3 PM2_5_DRY no no2 co \
  --heights 10 100 1000 \
  --output /path/to/output/extracted_file.nc
```

For multiple files:

```bash
python wrfchem_extract_par.py --input-folder /path/to/wrfout/files \
  --file-pattern "wrfout_d01_*" \
  --output-folder /path/to/output \
  --output-prefix "extracted_" \
  --vars O3 PM2_5_DRY no no2 co \
  --heights 10 100 1000 \
  --parallel-files \
  --max-parallel-files 2
```

### Advanced Multiprocessing Features

The script offers two levels of parallelization for optimal performance:

1. **Intra-file Parallelization**: Within each file, variables and time steps are processed in parallel.
   - Memory-adaptive chunking automatically determines optimal chunk sizes based on available system memory
   - Progress reporting with estimated time remaining
   - Memory usage monitoring to prevent out-of-memory errors

2. **Inter-file Parallelization**: Multiple files can be processed simultaneously.
   - Set via `--parallel-files` and `--max-parallel-files` options
   - Configure through the YAML config with `process_files_parallel` and `max_parallel_files`
   - Useful when processing many smaller files

### Requirements

- Python 3.6+
- numpy
- netCDF4
- wrf-python
- pyyaml
- psutil (for memory monitoring)

### Output

The script generates netCDF files containing:
- The specified variables at the requested heights
- Surface values for each variable (if requested)
- Metadata including time, latitude, and longitude

### Performance Tips

- For large WRF outputs with many variables, let the script determine chunk sizes automatically
- For systems with limited memory, reduce `max_parallel_files` to 1
- For systems with ample memory and multiple files to process, increase `max_parallel_files`
- Use `processes: null` in the config to auto-detect the optimal number of processes based on CPU cores