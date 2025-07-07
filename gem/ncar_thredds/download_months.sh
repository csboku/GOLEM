#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <year> [<month>...] [download_location]"
  echo "  <year>: The year to download data for."
  echo "  <month>: Optional. One or more months to download (e.g., 1 2 12)."
  echo "           If no months are provided, all months for the year will be downloaded."
  echo "  [download_location]: Optional. A directory to save files to."
  echo "                       Defaults to a directory named after the year."
  echo "Example: $0 2023 1 3"
  echo "Example: $0 2023 1 2 /my/data"
  exit 1
fi

YEAR=$1
shift

MONTHS=()
DOWNLOAD_LOCATION=""
ARGS=("$@")
if [ ${#ARGS[@]} -gt 0 ]; then
  LAST_ARG_INDEX=$((${#ARGS[@]} - 1))
  LAST_ARG=${ARGS[$LAST_ARG_INDEX]}
  # Simple heuristic: if the last argument is not a 1 or 2 digit number, it's the download location.
  if ! [[ "$LAST_ARG" =~ ^[0-9]{1,2}$ ]]; then
    DOWNLOAD_LOCATION=$LAST_ARG
    unset 'ARGS[$LAST_ARG_INDEX]'
  fi
fi
MONTHS=("${ARGS[@]}")

# If download location was not specified, use default.
if [ -z "$DOWNLOAD_LOCATION" ]; then
  DOWNLOAD_LOCATION="./${YEAR}"
fi

CATALOG_URL="https://thredds.rda.ucar.edu/thredds/catalog/files/g/d313007/${YEAR}/catalog.html"
BASE_URL="https://thredds.rda.ucar.edu/thredds/fileServer/files/g/d313007/${YEAR}"

# Check if the catalog URL exists before proceeding
if ! wget --spider -q "${CATALOG_URL}"; then
  echo "Error: Catalog for year ${YEAR} not found at ${CATALOG_URL}"
  exit 1
fi

MONTH_FILTER_REGEX=""
if [ ${#MONTHS[@]} -gt 0 ]; then
  echo "Filtering for months: ${MONTHS[*]}"
  # Pad months to two digits (e.g., 1 -> 01)
  for i in "${!MONTHS[@]}"; do
    printf -v MONTHS[i] "%02d" "${MONTHS[i]}"
  done
  # Create a regex like: \.2023-(01|02|12)-
  MONTH_FILTER_JOINED=$(IFS='|'; echo "${MONTHS[*]}")
  MONTH_FILTER_REGEX="\.${YEAR}-(${MONTH_FILTER_JOINED})-"
fi

echo "Fetching file list from catalog for year ${YEAR}..."
echo "Downloading files to: ${DOWNLOAD_LOCATION}"

# Create a directory for the downloads
mkdir -p "${DOWNLOAD_LOCATION}"

# Fetch the catalog HTML, extract the .nc file names
FILE_LIST=$(wget -qO- "${CATALOG_URL}" | grep -oP '<code>\K[^<]*\.nc')

# Filter by month if specified
if [ -n "$MONTH_FILTER_REGEX" ]; then
  FILE_LIST=$(echo "$FILE_LIST" | grep -E "$MONTH_FILTER_REGEX")
fi

if [ -z "$FILE_LIST" ]; then
  echo "No files found for the specified criteria."
  exit 0
fi

# Download the files
echo "$FILE_LIST" | while read -r FILE_NAME; do
  if [ -n "${FILE_NAME}" ]; then
    if [ -f "${DOWNLOAD_LOCATION}/${FILE_NAME}" ]; then
      echo "Skipping ${FILE_NAME}, already exists."
    else
      DOWNLOAD_URL="${BASE_URL}/${FILE_NAME}"
      echo "Downloading ${FILE_NAME}"
      wget -P "${DOWNLOAD_LOCATION}" "${DOWNLOAD_URL}"
    fi
  fi
done

echo "All downloads for ${YEAR} complete."
