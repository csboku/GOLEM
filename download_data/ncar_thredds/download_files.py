import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin

def download_files():
    """
    Connects to the specified URL, parses the HTML to find all file links,
    and downloads each file into a local directory.
    """
    # The URL of the catalog page containing the files
    catalog_url = "https://thredds.rda.ucar.edu/thredds/catalog/files/g/d313007/2016/catalog.html"

    # The base URL for constructing the direct download links for the files.
    # This is often different from the catalog URL.
    base_download_url = "https://thredds.rda.ucar.edu/thredds/fileServer/files/g/d313007/2016/"

    # The local directory where files will be saved
    download_directory = "/sto4/projects/BIOMASS_CC_AQ/geosphere/cam-chem/"

    # --- Step 1: Create the local download directory if it doesn't exist ---
    if not os.path.exists(download_directory):
        os.makedirs(download_directory)
        print(f"Created directory: '{download_directory}'")

    # --- Step 2: Fetch the content of the catalog page ---
    try:
        print(f"Fetching file list from {catalog_url}...")
        response = requests.get(catalog_url)
        # Raise an HTTPError if the HTTP request returned an unsuccessful status code
        response.raise_for_status()
    except requests.exceptions.RequestException as e:
        print(f"Error: Could not fetch the catalog URL. {e}")
        return

    # --- Step 3: Parse the HTML and extract file links ---
    # BeautifulSoup is used to parse the HTML content
    soup = BeautifulSoup(response.text, 'html.parser')

    # Find all 'a' tags, which are hyperlinks
    # Then find the 'code' tag within the 'a' tag to get the filename
    file_names = [
        node.get_text().strip() for node in soup.find_all('code')
        if node.get_text().strip().endswith('.nc')
    ]

    if not file_names:
        print("No downloadable '.nc' files were found on the page.")
        return

    print(f"Found {len(file_names)} files to download.")

    # --- Step 4: Download each file ---
    for name in file_names:
        # Construct the full URL for the file
        file_url = urljoin(base_download_url, name)

        # Define the local path to save the file
        local_file_path = os.path.join(download_directory, name)

        # Check if the file already exists to avoid re-downloading
        if os.path.exists(local_file_path):
            print(f"File '{name}' already exists. Skipping.")
            continue

        # Download the file
        try:
            print(f"Downloading '{name}'...")
            file_response = requests.get(file_url, stream=True)
            file_response.raise_for_status()

            # Save the file to the local directory
            with open(local_file_path, 'wb') as f:
                # Use iter_content to handle large files efficiently
                for chunk in file_response.iter_content(chunk_size=4096):
                    f.write(chunk)

            print(f"Successfully downloaded '{name}'")

        except requests.exceptions.RequestException as e:
            print(f"Error downloading '{name}'. Reason: {e}")

    print("\nDownload process finished.")

if __name__ == "__main__":
    download_files()
