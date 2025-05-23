import cdsapi
import sys

year = sys.argv[1]
month = sys.argv[2]

c = cdsapi.Client()

days = [range(1,32),range(1,30),range(1,32),range(1,31),range(1,32),range(1,31),range(1,32),range(1,32),range(1,31),range(1,32),range(1,31),range(1,32)]


c.retrieve(
'reanalysis-era5-pressure-levels',
{
    'product_type': 'reanalysis',
    'format': 'grib',
    'variable': [
        'geopotential','relative_humidity', 'temperature',
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
'ERA5_pl_'+str(year)+"_"+str(month).zfill(2)+'_'+'_p2.grib')
