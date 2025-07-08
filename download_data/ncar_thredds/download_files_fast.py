import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import concurrent.futures



# --- Configuration ---
# The URL of the catalog page containing the files
CATALOG_URL = "https://thredds.rda.ucar.edu/thredds/catalog/files/g/d313007/2016/catalog.html"
# The base URL for constructing the direct download links
BASE_DOWNLOAD_URL = "https://thredds.rda.ucar.edu/thredds/fileServer/files/g/d313007/2016/"
# The local directory where files will be saved
DOWNLOAD_DIRECTORY = "golem_downloaded_files"
# The number of concurrent download threads. Adjust based on your network capacity.
MAX_WORKERS = 10

def get_file_names(catalog_url):
    """
    Connects to the catalog URL, parses the HTML, and extracts file names.
    """
    print(f"Fetching file list from {catalog_url}...")
    try:
        response = requests.get(catalog_url)
        response.raise_for_status()  # Raise an exception for bad status codes
        soup = BeautifulSoup(response.text, 'html.parser')

        # Find all 'code' tags which contain the filenames, and filter for '.nc' files
        file_names = [
            node.get_text().strip() for node in soup.find_all('code')
            if node.get_text().strip().endswith('.nc')
        ]

        if not file_names:
            print("No downloadable '.nc' files were found on the page.")
            return []

        print(f"Found {len(file_names)} files to download.")
        return file_names
    except requests.exceptions.RequestException as e:
        print(f"Error: Could not fetch the catalog URL. {e}")
        return []

def download_file(file_name):
    """
    Downloads a single file from the given URL and saves it to the download directory.
    """
    file_url = urljoin(BASE_DOWNLOAD_URL, file_name)
    local_file_path = os.path.join(DOWNLOAD_DIRECTORY, file_name)

    # Skip downloading if the file already exists
    if os.path.exists(local_file_path):
        print(f"File '{file_name}' already exists. Skipping.")
        return f"Skipped: {file_name}"

    try:
        print(f"Starting download for '{file_name}'...")
        file_response = requests.get(file_url, stream=True)
        file_response.raise_for_status()

        # Save the file to the local directory
        with open(local_file_path, 'wb') as f:
            for chunk in file_response.iter_content(chunk_size=8192):
                f.write(chunk)

        print(f"Successfully downloaded '{file_name}'")
        return f"Success: {file_name}"
    except requests.exceptions.RequestException as e:
        print(f"Error downloading '{file_name}'. Reason: {e}")
        return f"Failed: {file_name} ({e})"

def main():
    """
    Main function to orchestrate the concurrent file download process.
    """
    # Create the local download directory if it doesn't exist
    if not os.path.exists(DOWNLOAD_DIRECTORY):
        os.makedirs(DOWNLOAD_DIRECTORY)
        print(f"Created directory: '{DOWNLOAD_DIRECTORY}'")

    # Get the list of all files to be downloaded
    file_names = get_file_names(CATALOG_URL)
    if not file_names:
        return

    # Use a ThreadPoolExecutor to download files in parallel
    print(f"\nStarting concurrent download process with {MAX_WORKERS} workers...")
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        # The 'map' function applies 'download_file' to each item in 'file_names'
        # and returns an iterator for the results.
        results = executor.map(download_file, file_names)

        # You can process results here if needed, but for now, we just let it run.
        # The loop will effectively wait for all downloads to complete.
        for result in results:
            pass  # The print statements are inside the download_file function

    print("\nAll download tasks have been processed.")

if __name__ == "__main__":
    main()
