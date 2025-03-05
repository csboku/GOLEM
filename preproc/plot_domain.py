import matplotlib.pyplot as plt
import cartopy.crs as ccrs
import cartopy.feature as cfeature
import numpy as np

# Define domain coordinates based on your configuration
# Center point
center_lat = 46.7
center_lon = 10.0

# Domain sizes in km
d01_size = 2430  # 270*9km
d02_size = 750   # 250*3km
d03_size = 150   # 150*1km

# Convert to degrees (approximate)
km_per_degree_lat = 111
km_per_degree_lon = 111 * np.cos(np.radians(center_lat))

d01_lat_half = d01_size / (2 * km_per_degree_lat)
d01_lon_half = d01_size / (2 * km_per_degree_lon)
d02_lat_half = d02_size / (2 * km_per_degree_lat)
d02_lon_half = d02_size / (2 * km_per_degree_lon)
d03_lat_half = d03_size / (2 * km_per_degree_lat)
d03_lon_half = d03_size / (2 * km_per_degree_lon)

# Create figure
fig = plt.figure(figsize=(12, 10))
ax = plt.axes(projection=ccrs.PlateCarree())

# Add map features
ax.add_feature(cfeature.COASTLINE.with_scale('50m'), linewidth=0.5)
ax.add_feature(cfeature.BORDERS.with_scale('50m'), linewidth=0.5)
ax.add_feature(cfeature.OCEAN.with_scale('50m'), zorder=0)
ax.add_feature(cfeature.LAND.with_scale('50m'), zorder=0, edgecolor='black')

# Plot domains
# d01 - European domain
d01_box = plt.Rectangle((center_lon-d01_lon_half, center_lat-d01_lat_half),
                        2*d01_lon_half, 2*d01_lat_half,
                        fill=False, edgecolor='red', linewidth=2,
                        transform=ccrs.PlateCarree(), label='d01 (9km)')

# d02 - Alps domain
d02_box = plt.Rectangle((center_lon-d02_lon_half, center_lat-d02_lat_half),
                        2*d02_lon_half, 2*d02_lat_half,
                        fill=False, edgecolor='blue', linewidth=2,
                        transform=ccrs.PlateCarree(), label='d02 (3km)')

# d03 - Arosa & Davos domain
d03_box = plt.Rectangle((center_lon-d03_lon_half, center_lat-d03_lat_half),
                        2*d03_lon_half, 2*d03_lat_half,
                        fill=False, edgecolor='green', linewidth=2,
                        transform=ccrs.PlateCarree(), label='d03 (1km)')

ax.add_patch(d01_box)
ax.add_patch(d02_box)
ax.add_patch(d03_box)

# Add cities of interest
plt.plot(9.82, 46.78, 'ko', markersize=5, transform=ccrs.PlateCarree())  # Arosa
plt.text(9.82, 46.78-0.1, 'Arosa', transform=ccrs.PlateCarree(), fontsize=10)
plt.plot(9.84, 46.80, 'ko', markersize=5, transform=ccrs.PlateCarree())  # Davos
plt.text(9.84, 46.80+0.1, 'Davos', transform=ccrs.PlateCarree(), fontsize=10)

# Set extent to show all domains
ax.set_extent([center_lon-d01_lon_half*1.1, center_lon+d01_lon_half*1.1,
               center_lat-d01_lat_half*1.1, center_lat+d01_lat_half*1.1],
              crs=ccrs.PlateCarree())

ax.gridlines(draw_labels=True)
plt.legend(handles=[d01_box, d02_box, d03_box])
plt.title('WRF-Chem Domains for STOA Project')

plt.savefig('wrf_domains.png', dpi=300, bbox_inches='tight')
plt.show()
