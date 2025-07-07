#!/bin/bash

BASE_URL="https://thredds.rda.ucar.edu/thredds/"
PATH_HISTORY=("catalog.html")
CURRENT_PATH="catalog.html"

# Function to download files
download_files() {
    local catalog_path=$1
    local year=$2
    local month=$3
    local location=$4

    # Construct the base URL for file downloads from the catalog path
    local dataset_path
    dataset_path=$(echo "$catalog_path" | sed 's/catalog.html?dataset=//' | sed 's/\/catalog.html//')
    local download_base_url="${BASE_URL}fileServer/${dataset_path}"
    local file_list_url="${BASE_URL}${catalog_path}"

    mkdir -p "${location}"
    echo "Downloading files to: ${location}"

    local file_pattern
    if [ -n "$month" ]; then
        file_pattern="${year}-${month}"
    else
        file_pattern="${year}-"
    fi

    echo "Fetching file list from ${file_list_url}"
    
    # Get the list of files to download
    local files_to_download
    mapfile -t files_to_download < <(wget -qO- "${file_list_url}" 2>/dev/null | grep -oP '<code>\K[^<]*\.nc' | grep "${file_pattern}" || true)

    if [ ${#files_to_download[@]} -eq 0 ]; then
        echo "No files found for the specified year/month."
        sleep 2
        return
    fi

    echo "${#files_to_download[@]} files to download."
    
    for FILE_NAME in "${files_to_download[@]}"; do
        local DOWNLOAD_URL="${download_base_url}/${FILE_NAME}"
        echo "Downloading ${FILE_NAME}"
        wget -P "${location}" "${DOWNLOAD_URL}"
    done

    echo "Download complete."
    sleep 2
}

# Function to prompt for download options
prompt_for_download() {
    local catalog_path=$1
    clear
    echo "This dataset contains downloadable files."
    echo "----------------------------------------"
    echo "What would you like to do?"
    PS3="Your choice: "
    select action in "Download by Year" "Download by Month" "Back to previous menu"; do
        case $action in
            "Download by Year")
                read -p "Enter the year to download: " year
                read -p "Enter the download location (default: ./downloads/${year}): " location
                location=${location:-./downloads/${year}}
                download_files "${catalog_path}" "${year}" "" "${location}"
                break
                ;;
            "Download by Month")
                read -p "Enter the year (e.g., 2017): " year
                read -p "Enter the month (e.g., 01 for Jan): " month
                read -p "Enter the download location (default: ./downloads/${year}-${month}): " location
                location=${location:-./downloads/${year}-${month}}
                download_files "${catalog_path}" "${year}" "${month}" "${location}"
                break
                ;;
            "Back to previous menu")
                break
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
    done
}

# Main application loop
while true; do
    clear
    display_path=$(echo "${CURRENT_PATH}" | sed -e 's/catalog.html?dataset=//' -e 's/\/catalog.html//' -e 's/.$//')
    echo "Current location: /${display_path}"
    echo "--------------------------------------------------"

    # Fetch the HTML and parse it to find catalog links and their descriptions
    # This regex is designed to be more robust and capture the descriptive text.
    mapfile -t catalog_entries < <(wget -qO- "${BASE_URL}${CURRENT_PATH}" 2>/dev/null | \
        grep -oP '<a href="catalog[^"]*">\s*<code>.*?<\/code>' | \
        sed -e 's/<a href="\([^"]*\)">\s*<code>\([^<]*\)<\/code>/\2\t\1/' | \
        grep -v "Parent Directory" | sort -u)

    # Check for downloadable .nc files on the page
    mapfile -t downloadable_files < <(wget -qO- "${BASE_URL}${CURRENT_PATH}" 2>/dev/null | grep -oP '<code>\K[^<]*\.nc')

    if [ ${#downloadable_files[@]} -gt 0 ] && [ ${#catalog_entries[@]} -eq 0 ]; then
        prompt_for_download "${CURRENT_PATH}"
        if [ ${#PATH_HISTORY[@]} -gt 1 ]; then
            unset 'PATH_HISTORY[${#PATH_HISTORY[@]}-1]'
            CURRENT_PATH=${PATH_HISTORY[${#PATH_HISTORY[@]}-1]}
        fi
        continue
    fi

    if [ ${#catalog_entries[@]} -eq 0 ]; then
        echo "No further datasets found."
        sleep 2
        if [ ${#PATH_HISTORY[@]} -gt 1 ]; then
            unset 'PATH_HISTORY[${#PATH_HISTORY[@]}-1]'
            CURRENT_PATH=${PATH_HISTORY[${#PATH_HISTORY[@]}-1]}
        else
            echo "At the top level. Exiting."
            exit 0
        fi
        continue
    fi

    options=()
    urls=()
    for entry in "${catalog_entries[@]}"; do
        options+=("$(echo "$entry" | cut -f1)")
        urls+=("$(echo "$entry" | cut -f2)")
    done
    options+=("Back" "Quit")

    echo "Please select a dataset:"
    PS3="Your choice: "
    COLUMNS=1
    select choice in "${options[@]}"; do
        case "$choice" in
            "Quit")
                exit 0
                ;;
            "Back")
                if [ ${#PATH_HISTORY[@]} -gt 1 ]; then
                    unset 'PATH_HISTORY[${#PATH_HISTORY[@]}-1]'
                    CURRENT_PATH=${PATH_HISTORY[${#PATH_HISTORY[@]}-1]}
                else
                    echo "Already at the top level."
                fi
                break
                ;;
            *)
                if [ -n "$choice" ]; then
                    for i in "${!options[@]}"; do
                       if [[ "${options[$i]}" = "${choice}" ]]; then
                           next_path=${urls[$i]}
                           PATH_HISTORY+=("$next_path")
                           CURRENT_PATH=$next_path
                           break 2
                       fi
                    done
                else
                    echo "Invalid selection. Please try again."
                fi
                ;;
        esac
    done
done
