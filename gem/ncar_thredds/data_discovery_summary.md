# Data Discovery and Download Scripts

This document summarizes the two bash scripts created to download data from the [THREDDS Data Server](https://thredds.rda.ucar.edu/thredds/catalog/catalog.html).

## Scripts

### 1. `download.sh`

This script is designed for direct, non-interactive downloading of data for a specific year.

**Usage:**

```bash
./download.sh <year> [download_location]
```

*   `<year>`: The year of the data you want to download (e.g., `2017`).
*   `[download_location]` (optional): The directory where you want to save the files. If not provided, a directory named after the year will be created in the current location.

**How it works:**

The script first fetches the catalog page for the specified year. It then parses the HTML to find all the `.nc` file links on that page and downloads them sequentially using `wget`.

### 2. `browse.sh`

This script provides an interactive way to browse the THREDDS data catalog from your terminal. It allows you to navigate through the datasets and then choose to download data for a specific year or month.

**Usage:**

```bash
./browse.sh
```

The script will present you with a menu of available datasets. You can select a dataset to navigate deeper into the catalog. When you reach a downloadable dataset, you will be prompted to download by year or month.

**How it works:**

The script starts at the top-level catalog and dynamically fetches and parses the HTML of each page you navigate to. It uses `grep` and `sed` to extract the dataset names and links, presenting them to you in a menu. When you choose to download, it uses a similar mechanism to `download.sh` to fetch the files for the specified period.

## Development Journey & Key Findings

The development of these scripts involved a few challenges:

1.  **Dynamic URLs:** We initially assumed a consistent URL and filename structure across all years. However, we discovered that the filenames for 2017 were different from 2016. This led to `404 Not Found` errors.
2.  **Robust Parsing:** To solve the dynamic URL issue, we switched to a more robust strategy: fetching the catalog page and parsing it to get the actual filenames. This is a more reliable approach than trying to guess the filenames.
3.  **Interactive Browsing:** For the `browse.sh` script, we initially had issues with the menu display and parsing the sub-pages. We resolved this by implementing a more intelligent parsing mechanism that could handle the structure of both the top-level catalog and the sub-pages, and by carefully managing the navigation history.

The final scripts are now much more robust and user-friendly as a result of this iterative development process.
