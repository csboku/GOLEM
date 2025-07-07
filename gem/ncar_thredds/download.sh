#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <year> [download_location]"
  exit 1
fi

YEAR=$1
DOWNLOAD_LOCATION=${2:-./${YEAR}} # Default to a directory named after the year

CATALOG_URL="https://thredds.rda.ucar.edu/thredds/catalog/files/g/d313007/${YEAR}/catalog.html"
BASE_URL="https://thredds.rda.ucar.edu/thredds/fileServer/files/g/d313007/${YEAR}"

# Check if the catalog URL exists before proceeding
if ! wget --spider -q "${CATALOG_URL}"; then
  echo "Error: Catalog for year ${YEAR} not found at ${CATALOG_URL}"
  exit 1
fi

echo "Fetching file list from catalog for year ${YEAR}..."
echo "Downloading files to: ${DOWNLOAD_LOCATION}"

# Create a directory for the downloads
mkdir -p "${DOWNLOAD_LOCATION}"

# Fetch the catalog HTML, extract the .nc file names, and download them.
wget -qO- "${CATALOG_URL}" | \
grep -oP '<code>\K[^<]*\.nc' | \
while read -r FILE_NAME; do
  if [ -n "${FILE_NAME}" ]; then
    DOWNLOAD_URL="${BASE_URL}/${FILE_NAME}"
    echo "Downloading ${FILE_NAME}"
    wget -P "${DOWNLOAD_LOCATION}" "${DOWNLOAD_URL}"
  fi
done

echo "All downloads for ${YEAR} complete."
