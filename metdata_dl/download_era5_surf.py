import cdsapi
import sys
import calendar

def download_era5_surf_data(year_str, month_str):
    """
    Downloads ERA5 surface level data for a given year and month.
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

    # It's good practice to add a check for valid year range for ERA5 data if known.
    # e.g., if not (1950 <= year <= current_year): print("Error: Year out of range for ERA5 data.")

    c = cdsapi.Client()

    # Determine the number of days in the month
    num_days_in_month = calendar.monthrange(year, month)[1]

    # Define day lists for part 1 (days 1-18) and part 2 (days 19-end of month)
    # The API expects days as strings, e.g., '01', '02', ..., '31'
    days_part1 = [str(d).zfill(2) for d in range(1, min(19, num_days_in_month + 1))]
    days_part2 = [str(d).zfill(2) for d in range(19, num_days_in_month + 1)]

    common_params = {
        'product_type': 'reanalysis',
        'format': 'grib',
        'variable': [
            '10m_u_component_of_wind', '10m_v_component_of_wind', '2m_dewpoint_temperature',
            '2m_temperature', 'convective_snowfall', 'convective_snowfall_rate_water_equivalent',
            'ice_temperature_layer_1', 'ice_temperature_layer_2', 'ice_temperature_layer_3',
            'ice_temperature_layer_4', 'land_sea_mask', 'large_scale_snowfall',
            'large_scale_snowfall_rate_water_equivalent', 'maximum_2m_temperature_since_previous_post_processing', 'mean_sea_level_pressure',
            'mean_wave_direction', 'mean_wave_period', 'minimum_2m_temperature_since_previous_post_processing',
            'sea_ice_cover', 'sea_surface_temperature', 'significant_height_of_combined_wind_waves_and_swell',
            'skin_temperature', 'snow_albedo', 'snow_density',
            'snow_depth', 'snow_evaporation', 'snowfall',
            'snowmelt', 'soil_temperature_level_1', 'soil_temperature_level_2',
            'soil_temperature_level_3', 'soil_temperature_level_4', 'soil_type',
            'surface_pressure', 'temperature_of_snow_layer', 'total_column_snow_water',
            'total_precipitation', 'volumetric_soil_water_layer_1', 'volumetric_soil_water_layer_2',
            'volumetric_soil_water_layer_3', 'volumetric_soil_water_layer_4',
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
            85, -30, 30, # North, West, South, East
            65,
        ],
    }

    # Part 1: Days 1-18 (or up to num_days_in_month if less than 18)
    if days_part1:
        request_params_p1 = common_params.copy()
        request_params_p1['day'] = days_part1
        output_filename_p1 = f'ERA5_sf_{year}_{str(month).zfill(2)}_p1.grib'

        print(f"Requesting part 1 surface data for {year}-{str(month).zfill(2)}, days: {days_part1}")
        print(f"Output file: {output_filename_p1}")
        try:
            c.retrieve('reanalysis-era5-single-levels', request_params_p1, output_filename_p1)
            print(f"Successfully downloaded {output_filename_p1}")
        except Exception as e:
            print(f"Error downloading {output_filename_p1}: {e}")
            sys.exit(1) # Exit if part 1 fails

    # Part 2: Days 19 to end of month
    if days_part2: # This check ensures we don't try to download part 2 if the month has < 19 days
        request_params_p2 = common_params.copy()
        request_params_p2['day'] = days_part2
        output_filename_p2 = f'ERA5_sf_{year}_{str(month).zfill(2)}_p2.grib'

        print(f"Requesting part 2 surface data for {year}-{str(month).zfill(2)}, days: {days_part2}")
        print(f"Output file: {output_filename_p2}")
        try:
            c.retrieve('reanalysis-era5-single-levels', request_params_p2, output_filename_p2)
            print(f"Successfully downloaded {output_filename_p2}")
        except Exception as e:
            print(f"Error downloading {output_filename_p2}: {e}")
            # Decide on error strategy: exit or allow partial success
            # For now, we'll print error and continue, assuming part 1 might be useful.

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python download_era5_surf.py <year> <month>")
        sys.exit(1)

    year_arg = sys.argv[1]
    month_arg = sys.argv[2]

    download_era5_surf_data(year_arg, month_arg)
    print("Download process for surface data finished.")
