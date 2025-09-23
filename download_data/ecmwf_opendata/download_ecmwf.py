import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse

# --- CONFIGURATION ---
start_url = 'https://data.ecmwf.int/forecasts/'
base_output_dir = 'ecmwf_ifs_data'
# --- END CONFIGURATION ---

visited_links = set()

def download_and_crawl(url, current_path):
    if url in visited_links:
        return
    print(f"-> Visiting Directory: {url}")
    visited_links.add(url)

    os.makedirs(current_path, exist_ok=True)

    try:
        response = requests.get(url, timeout=15)
        response.raise_for_status()
        soup = BeautifulSoup(response.content, 'html.parser')

        for link_tag in soup.find_all('a'):
            href = link_tag.get('href')

            if not href or href.startswith('?') or href.startswith('#'):
                continue

            absolute_link = urljoin(url, href)

            # Ensure the link stays within the original website path
            if not absolute_link.startswith(start_url):
                continue
            
            # --- REVISED LOGIC ---
            # If the link is a directory, crawl into it.
            if href.endswith('/'):
                new_dir_name = href.strip('/')
                new_path = os.path.join(current_path, new_dir_name)
                download_and_crawl(absolute_link, new_path)
            # If it's a file, check if it contains "ifs" BEFORE downloading.
            else:
                if 'ifs/0p25/oper/' in href.lower():
                    download_file(absolute_link, current_path)

    except requests.exceptions.RequestException as e:
        print(f"!! ERROR: Could not connect to {url}: {e}")
    except Exception as e:
        print(f"!! An unexpected error occurred at {url}: {e}")

def download_file(file_url, download_path):
    try:
        filename = os.path.basename(urlparse(file_url).path)
        local_filepath = os.path.join(download_path, filename)

        if os.path.exists(local_filepath):
            print(f"  - Exists: {filename}")
            return

        print(f"  - Downloading: {filename}")
        
        with requests.get(file_url, stream=True) as r:
            r.raise_for_status()
            with open(local_filepath, 'wb') as f:
                for chunk in r.iter_content(chunk_size=8192):
                    f.write(chunk)
        print(f"  - Success: Saved '{filename}'")

    except requests.exceptions.RequestException as e:
        print(f"!! ERROR downloading {file_url}: {e}")

# --- Main execution block ---
if __name__ == "__main__":
    print(f"Starting ECMWF IFS data crawler in: {start_url}")
    print(f"Output will be saved to: '{base_output_dir}'")
    download_and_crawl(start_url, base_output_dir)
    print("\nProcess finished.")