from bs4 import BeautifulSoup
import requests
import lxml
import html
from urllib.parse import urljoin,urlparse
import os

os.chdir("/home/cschmidt/git/GOLEM/download_data/rcp_database")

url = "https://tntcat.iiasa.ac.at/RcpDb/dsd?Action=htmlpage&page=download"

response = requests.get(url)


# soup = BeautifulSoup('./RCP Database_files/dsd.html','html.parser')


with open("./RCP Database_files/dsd.html",'rb') as fp:
    soup = BeautifulSoup(fp,'html.parser')

# Find all <a> tags with a 'href' attribute starting with 'https://'

# links = soup.find_all('a')
all_links = soup.find_all('a', attrs={'href': lambda href: href and href.startswith('https://')})

absolute_links = set()

for link_tag in soup.find_all('a'):
    href = link_tag.get('href')
    if not href:
        continue
    full_url = urljoin(url,href)
    absolute_links.add(full_url)

output_dir = "/mnt/lacie/data/RCP/"

# Loop through each URL in your set
for url in absolute_links:
    try:
        # Get the filename from the URL
        parsed_url = urlparse(url)
        # os.path.basename will get the last part of the path (the filename)
        filename = os.path.basename(parsed_url.path)

        # If the filename is empty (e.g., for a base URL like "http://example.com"), skip it
        if not filename:
            print(f"Skipping URL with no filename: {url}")
            continue

        # Construct the full local path for the file
        local_filepath = os.path.join(output_dir, filename)

        # --- Check if the file already exists ---
        if os.path.exists(local_filepath):
            print(f"Exists: '{filename}'")
            continue

        # --- If it doesn't exist, download it ---
        print(f"Downloading: '{filename}' from {url}")
        
        # Make the request with streaming to handle large files
        response = requests.get(url, stream=True)
        response.raise_for_status()  # Raise an exception for bad status codes (4xx or 5xx)

        # Write the file to disk in chunks
        with open(local_filepath, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        print(f"Success: Saved '{filename}'")

    except requests.exceptions.RequestException as e:
        # Handle network-related errors
        print(f"Error downloading {url}: {e}")
    except Exception as e:
        # Handle other potential errors
        print(f"An unexpected error occurred for {url}: {e}")

print("\nAll downloads attempted. Process finished.")