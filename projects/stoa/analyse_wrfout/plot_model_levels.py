import salem
import matplotlib.pyplot as plt
import numpy as np

# Open your WRF file
ds = salem.open_wrf_dataset('/home/cschmidt/data/STOA/wrfout/test_run_1/wrfout_d01_2004-06-05_10:00:00')

# Get the heights - check if Salem computed correctly or we need to do it manually
try:
    z = ds.Z.isel(time=0)  # Salem's computed height
    print(f"Using Salem's Z field, max height: {z.max().values:.1f} m")
except:
    # Manual calculation: (PH + PHB) / g
    ph = ds.PH.isel(time=0)
    phb = ds.PHB.isel(time=0)
    z = (ph + phb) / 9.81
    print(f"Manual height calculation, max height: {z.max().values:.1f} m")

terrain = ds.HGT

# Check actual height values
print(f"Height field shape: {z.shape}")
print(f"Height range: {z.min().values:.1f} to {z.max().values:.1f} m")

# Figure 1: Vertical cross-section
fig1, ax1 = plt.subplots(1, 1, figsize=(12, 8))

# Panel 1: Cross-section showing how levels follow terrain
# Take a slice through the middle of your domain
mid_y = ds.sizes['south_north'] // 2
z_cross = z.isel(south_north=mid_y)

# Get x-coordinates (distance in km from domain center)
# WRF uses dx spacing - typically need to get this from attributes
try:
    dx = ds.attrs.get('DX', 1000)  # Default 1km if not found
except:
    dx = 1000
    
west_east_coords = np.arange(ds.sizes['west_east']) * dx / 1000  # Convert to km
west_east_coords = west_east_coords - west_east_coords[len(west_east_coords)//2]  # Center on domain

# Plot each model level as a line
for k in range(ds.sizes['bottom_top']):
    ax1.plot(west_east_coords, z_cross[k, :].values, 'b-', alpha=0.6, linewidth=0.5)

# Add terrain profile
terrain_profile = terrain.isel(south_north=mid_y)
if len(terrain_profile.dims) > 1:
    terrain_profile = terrain_profile.squeeze()
terrain_1d = terrain_profile.values
if len(terrain_1d.shape) > 1:
    terrain_1d = terrain_1d.flatten()

# Ensure terrain matches west_east dimension
if len(terrain_1d) != len(west_east_coords):
    terrain_1d = terrain_1d[:len(west_east_coords)]

ax1.fill_between(west_east_coords,
                 0,
                 terrain_1d,
                 color='saddlebrown', alpha=0.5, label='Terrain')

ax1.set_xlabel('Distance from Domain Center (km)')
ax1.set_ylabel('Height (m)')
ax1.set_title(f'WRF Model Levels - Vertical Cross Section ({ds.sizes["bottom_top"]} levels)')
ax1.grid(True, alpha=0.3)
ax1.legend()

plt.tight_layout()
plt.savefig('wrf_vertical_cross_section.png', dpi=100, bbox_inches='tight')
print("Vertical cross-section saved as wrf_vertical_cross_section.png")
plt.close()

# Figure 2: Vertical resolution (level spacing) at a single column
fig2, ax2 = plt.subplots(1, 1, figsize=(8, 10))
# Pick a point - maybe domain center or max terrain
mid_x = ds.sizes['west_east'] // 2
z_column = z.isel(west_east=mid_x, south_north=mid_y).values
level_spacing = np.diff(z_column)
level_centers = (z_column[:-1] + z_column[1:]) / 2

ax2.plot(level_spacing, level_centers, 'r-o', markersize=4)
ax2.set_xlabel('Level Spacing (m)')
ax2.set_ylabel('Height (m)')
ax2.set_title('Vertical Resolution')
ax2.grid(True, alpha=0.3)

# Add surface height line
surface_height = terrain.isel(west_east=mid_x, south_north=mid_y)
if hasattr(surface_height, 'values'):
    surface_height = float(surface_height.values.flatten()[0])
else:
    surface_height = float(surface_height)

ax2.axhline(y=surface_height,
            color='saddlebrown', linestyle='--', label='Surface')
ax2.legend()

plt.tight_layout()
plt.savefig('wrf_vertical_resolution.png', dpi=100, bbox_inches='tight')
print("Vertical resolution plot saved as wrf_vertical_resolution.png")
plt.close()

# Print some useful info about your configuration
print(f"\nWRF Configuration Summary:")
print(f"Number of vertical levels: {ds.sizes['bottom_top']}")
print(f"Top of model domain: {z.max().values:.1f} m")
print(f"Terrain height range: {terrain.min().values:.1f} - {terrain.max().values:.1f} m")
print(f"Domain size: {ds.sizes['west_east']} × {ds.sizes['south_north']} grid points")
