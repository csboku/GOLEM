import sys
import time

# Assuming download_era5_plev.py and download_era5_surf.py are in the same directory
# and their main functions are importable.
# If they are not structured to be easily importable (e.g., all logic is under if __name__ == '__main__'),
# they would need to be refactored. For now, let's assume they have callable functions.

try:
    from download_era5_plev import download_era5_plev_data
    from download_era5_surf import download_era5_surf_data
except ImportError as e:
    print(f"Error importing download functions: {e}")
    print("Make sure download_era5_plev.py and download_era5_surf.py are in the same directory or in PYTHONPATH.")
    sys.exit(1)

def download_yearly_data(year_str):
    """
    Downloads ERA5 pressure level and surface data for all months of a given year.
    """
    try:
        year = int(year_str)
    except ValueError:
        print("Error: Year must be an integer.")
        sys.exit(1)

    # Add any specific year validation if necessary (e.g., range for ERA5 availability)
    # if not (1950 <= year <= current_year):
    #     print(f"Error: Year {year} is out of the typical ERA5 availability range.")
    #     sys.exit(1)

    print(f"Starting download process for the year: {year}")

    for month in range(1, 13):
        month_str = str(month).zfill(2) # Ensure month is two digits (e.g., '01', '02', ..., '12')

        print(f"\n--- Downloading data for {year}-{month_str} ---")

        # Download pressure level data
        print(f"--- Initiating pressure level data download for {year}-{month_str} ---")
        try:
            download_era5_plev_data(str(year), month_str)
            print(f"--- Completed pressure level data download for {year}-{month_str} ---")
        except SystemExit as e:
            # SystemExit is raised by the download scripts on argument or critical API errors
            print(f"--- Pressure level download for {year}-{month_str} exited with code {e.code}. Skipping to next. ---")
            if e.code != 0 and e.code != 1 : # Allow skipping if a specific download part fails but not if input args are bad
                 # Potentially add more nuanced error handling here if needed
                 pass # Continue to surface data or next month
        except Exception as e:
            print(f"--- An unexpected error occurred during pressure level data download for {year}-{month_str}: {e} ---")
            print(f"--- Skipping pressure level data for {year}-{month_str} ---")

        # Optional: Add a small delay between dataset type downloads if desired
        time.sleep(2) # 2-second delay

        # Download surface level data
        print(f"--- Initiating surface level data download for {year}-{month_str} ---")
        try:
            download_era5_surf_data(str(year), month_str)
            print(f"--- Completed surface level data download for {year}-{month_str} ---")
        except SystemExit as e:
            print(f"--- Surface level download for {year}-{month_str} exited with code {e.code}. Skipping to next. ---")
            if e.code != 0 and e.code != 1:
                 pass # Continue to next month
        except Exception as e:
            print(f"--- An unexpected error occurred during surface level data download for {year}-{month_str}: {e} ---")
            print(f"--- Skipping surface level data for {year}-{month_str} ---")

        if month < 12:
            print(f"\n--- Moving to the next month ---")
            time.sleep(5) # 5-second delay before starting the next month's downloads

    print(f"\nAll download tasks for the year {year} have been processed.")

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python download_era5_year.py <year>")
        sys.exit(1)

    year_argument = sys.argv[1]
    download_yearly_data(year_argument)
