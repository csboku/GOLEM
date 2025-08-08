# Project Overview

This repository contains a diverse collection of code, documentation, and tools related to atmospheric modeling, data processing, and system utilities. The contents are organized into several key directories:

## Directory Structure and Contents:

*   **`code/`**:
    *   Contains source code primarily in Python, Julia, and R.
    *   Includes `GOLEM.py`, `GOLEM.jl`, `GOLEM_R.R` and their respective example usage files (`example_usage.jl`, `example_usage_R.R`, `example_usage_python.py`).
    *   The `codebase/` subdirectory holds more specialized scripts like `attain_init.jl`, `attain_report.jl`, `easy_nafix.R`, `na_fix.R`, `paper_attain.R`, `paper_attain.jl`, and `test_help.jl`.
    *   Also contains a general `example.py` and `README.md` for this section.

*   **`doc/`**:
    *   Houses various documentation files.
    *   Includes `KPP.odt` and `WRF_v3.8 Installation_Best_Practices.pdf`.
    *   The `doc/markdown/` subdirectory contains markdown-based guides on topics such as `datalad_guide.md`, `hpc_tools.md`, and `pixi_manual.md`.
    *   Detailed architectural documentation for "graphcast" can be found under `doc/graphcast/`.

*   **`download_data/`**:
    *   Scripts for downloading various datasets.
    *   `era5_dl/`: Python scripts for downloading ERA5 reanalysis data (`download_era5_plev.py`, `download_era5_surf.py`, `download_era5_year.py`).
    *   `ncar_thredds/`: Julia and Python scripts for downloading files from NCAR Thredds servers (`dl.jl`, `download_files.py`, `download_files_fast.py`).
    *   `py-cs-api-download/`: Python scripts and READMEs for interacting with a Python API for data download (`cs-geo-api-cli.py`, `cs-geo-api.py`, `README.md`, `README_CLI.md`).

*   **`geo_api/`**:
    *   Contains `geo_api.jl`, likely a Julia-based API for geographical data processing.

*   **`gem/`**:
    *   Related to a component named "gem".
    *   `ncar_thredds/`: Scripts and documentation (`browse.sh`, `data_discovery_summary.md`, `download.sh`, `download_months.sh`) for data discovery and download from NCAR Thredds within the "gem" context.
    *   `codeco/`: Includes `sin_plot.jl`.

*   **`kiwiwiki/boku/`**:
    *   Contains markdown files (`index.md`, `to-do.md`), possibly for a personal wiki or notes.

*   **`linux/`**:
    *   A collection of markdown files providing tips, configurations, and tutorials for Linux environments.
    *   Topics include: `kitty-shortcuts.md`, `linux-rename-tutorial.md`, `nvim-keymaps.md` (and a PDF version), `regex-summary.md`, `rename-perl-regex-guide.md`, and `yazi-cheatsheet.md` (and `yazi_cheat_sheet.md`).
    *   Includes `neovim/lazy.md` and `rsync/` tutorials and exclusion lists.

*   **`postproc/`**:
    *   Scripts and configuration for post-processing.
    *   `wrfchem_extract_par.py`: Python script for extracting WRF-Chem parameters.
    *   `config.yaml`: Configuration file.
    *   Includes a `README.md`.

*   **`preproc/`**:
    *   Scripts and images for pre-processing.
    *   `plot_domain.py`: Python script for plotting domains.
    *   `wrf_domains.png`: Image of WRF domains.

*   **`projects/stoa/`**:
    *   Contains `namelist.input`, likely a configuration file for a specific project run.

*   **`sw/`**:
    *   Software-related files.
    *   `containers/`: Contains shell scripts and definition files for container environments (`wrf_env.sh`, `wrfchem_amd_flang.def`).
    *   `numerics/`: Documentation and examples related to numerical computations (`code_native.md`, `matmult_amd.txt`, `matmult_intel.txt`).
    *   `vsc/`: Environment scripts specific to VSC (Tier 2 cluster in Belgium) (`env.sh`, `vsc_module.txt`).

*   **`tools/data_downloader/`**:
    *   `downloader.jl`: A Julia script for data downloading.

*   **`trurl/`**:
    *   Includes its own `README.md`.
    *   `archive/`: Contains `archive.tar.gz`.
    *   `python/`: Scripts for a Python-based NetCDF viewer, including build, run, and setup scripts (`build.sh`, `netcdf_viewer.py`, `requirements.txt`, `run.sh`, `setup.sh`).

*   **`vsc/`**:
    *   Shell scripts for managing jobs on a Slurm cluster.
    *   `check_slurm.sh`, `live_slurm.sh`.

*   **`wrfchem/`**:
    *   Extensive files and configurations for the WRF-Chem model.
    *   `ATTAIN_runs/`: Scripts for managing WRF-Chem runs (`Manage_runs.sh`, `WRF.sh`, `WRFchem_config.sh`, `WRFchem_main.sh`, `WRFchem_namelist.sh`, `WRFchem_preproc.sh`, `WRFchem_run.sh`, `WRFexe.sh`, `WRFexe2.sh`, `namelist.input`, `real_job.sh`, `wrf_job.sh`).
    *   `BIOMASS_CC_AQ/`: Input files for specific chemical mechanisms (`MOZCART_MOSAIC.inp`, `exo_colden.inp`, `namelist.input`, `real_job.sh`, `wesely.inp`, `wrf_job_l.sh`, `wrf_job_l_1N.sh`).
    *   `Registry/`: Various WRF-Chem registry files.
    *   `STOA_runs/`: Run configurations (`namelist.input`, `namelist.input_megan`, `wrf_job_l.sh`).
    *   `config/`: Configuration scripts (`Config.pl`).
    *   `emission_registry/`: `registry.chem`.
    *   `runtime_estimation/`: Runtime estimation output files.
    *   `tools/`: Archives of various tools used with WRF-Chem, such as `ANTHRO.tar`, `EPA_ANTHRO_EMIS.tgz`, `TUV.phot.bz2`, `megan_bio_emiss.tar`, `mozbc.tar`, `prep_chem_sources_v1.4_08aug2013.tar.gz`, `prep_chem_sources_v1.5_24aug2015.tar.gz`, and `wes-coldens.tar`.
