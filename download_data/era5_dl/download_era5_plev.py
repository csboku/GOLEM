import cdsapi
import sys
import calendar

def download_era5_plev_data(year_str, month_str):
    """
    Downloads ERA5 pressure level data for a given year and month.
    Splits the download into two parts if necessary to avoid request size limits.
    """
    try:
        year = int(year_str)
        month = int(month_str)
    except ValueError:
        print("Error: Year and month must be integers.")
        sys.exit(1)

    if not (1 <= month <= 12):
        print("Error: Month must be between 1 and 12.")
        sys.exit(1)

    # Recommended to check year range if known for ERA5 data availability
    # For example: if not (1950 <= year <= current_year): print("Error: Year out of range.")

    c = cdsapi.Client()

    # Determine the number of days in the month
    num_days_in_month = calendar.monthrange(year, month)[1]

    days_part1 = [str(d).zfill(2) for d in range(1, min(11, num_days_in_month + 1))]
    days_part2 = [str(d).zfill(2) for d in range(11, min(21, num_days_in_month + 1))]
    days_part3 = [str(d).zfill(2) for d in range(21, num_days_in_month + 1)]

    common_params = {
        'product_type': 'reanalysis',
        'format': 'grib',
        'variable': [
            'geopotential', 'relative_humidity', 'temperature',
            'u_component_of_wind', 'v_component_of_wind',
        ],
        'pressure_level': [
            '1', '2', '3',
            '5', '7', '10',
            '20', '30', '50',
            '70', '100', '125',
            '150', '175', '200',
            '225', '250', '300',
            '350', '400', '450',
            '500', '550', '600',
            '650', '700', '750',
            '775', '800', '825',
            '850', '875', '900',
            '925', '950', '975',
            '1000',
        ],
        'year': str(year),
        'month': str(month).zfill(2),
        'time': [
            '00:00', '01:00', '02:00',
            '03:00', '04:00', '05:00',
            '06:00', '07:00', '08:00',
            '09:00', '10:00', '11:00',
            '12:00', '13:00', '14:00',
            '15:00', '16:00', '17:00',
            '18:00', '19:00', '20:00',
            '21:00', '22:00', '23:00',
        ],
        'area': [
            85, -30, 30,
            65,
        ],
    }

    # Part 1: Days 1-18 (or up to num_days_in_month if less than 18)
    if days_part1:
        request_params_p1 = common_params.copy()
        request_params_p1['day'] = days_part1
        output_filename_p1 = f'ERA5_pl_{year}_{str(month).zfill(2)}_p1.grib'

        print(f"Requesting part 1 data for {year}-{str(month).zfill(2)}, days: {days_part1}")
        print(f"Output file: {output_filename_p1}")
        try:
            c.retrieve('reanalysis-era5-pressure-levels', request_params_p1, output_filename_p1)
            print(f"Successfully downloaded {output_filename_p1}")
        except Exception as e:
            print(f"Error downloading {output_filename_p1}: {e}")
            sys.exit(1) # Exit if part 1 fails, as part 2 depends on the same month/year logic

    # Part 2: Days 19 to end of month
    if days_part2:
        request_params_p2 = common_params.copy()
        request_params_p2['day'] = days_part2
        output_filename_p2 = f'ERA5_pl_{year}_{str(month).zfill(2)}_p2.grib'

        print(f"Requesting part 2 data for {year}-{str(month).zfill(2)}, days: {days_part2}")
        print(f"Output file: {output_filename_p2}")
        try:
            c.retrieve('reanalysis-era5-pressure-levels', request_params_p2, output_filename_p2)
            print(f"Successfully downloaded {output_filename_p2}")
        except Exception as e:
            print(f"Error downloading {output_filename_p2}: {e}")
            # No sys.exit here, as part 1 might have been successful.
            # Or, decide if partial success is acceptable.
    if days_part3:
        request_params_p3 = common_params.copy()
        request_params_p3['day'] = days_part3
        output_filename_p3 = f'ERA5_pl_{year}_{str(month).zfill(2)}_p3.grib'

        print(f"Requesting part 3 data for {year}-{str(month).zfill(2)}, days: {days_part3}")
        print(f"Output file: {output_filename_p3}")
        try:
            c.retrieve('reanalysis-era5-pressure-levels', request_params_p3, output_filename_p3)
            print(f"Successfully downloaded {output_filename_p3}")
        except Exception as e:
            print(f"Error downloading {output_filename_p3}: {e}")
            # No sys.exit here, as part 1 might have been successful.
            # Or, decide if partial success is acceptable.



if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python download_era5_plev.py <year> <month>")
        sys.exit(1)

    year_arg = sys.argv[1]
    month_arg = sys.argv[2]

    download_era5_plev_data(year_arg, month_arg)
    print("Download process finished.")
