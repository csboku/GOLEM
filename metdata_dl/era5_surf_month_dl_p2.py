import cdsapi
import sys

year = sys.argv[1]
month = sys.argv[2]

c = cdsapi.Client()

#days = [range(1,32),range(1,29),range(1,32),range(1,31),range(1,32),range(1,31),range(1,32),range(1,31),range(1,32),range(1,31),range(1,31),range(1,32)]


c.retrieve(
    'reanalysis-era5-single-levels',
    {
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
        'year': year,
        'month': month,
    'day': [
        '19', '20','21',
        '22', '23','24',
        '25', '26', '27',
        '28', '29', '30',
        '31',
        ],
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
    },
    'ERA5_sf_'+str(year)+"_"+str(month).zfill(2)+'_p2.grib')
