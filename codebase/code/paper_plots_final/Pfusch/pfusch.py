import numpy as np
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec

# Set style and figure size
plt.style.use('seaborn-v0_8-whitegrid')
fig = plt.figure(figsize=(12, 8))
gs = gridspec.GridSpec(2, 2, height_ratios=[1, 0.7], hspace=0.3)

# Colors matching your original plot
colors = ['#006D77', '#FFB84C', '#F24C3D', '#8B4513', '#642C0C']

# Box plot data (replace with your actual data)
labels = ['Allyear', 'MAM', 'JJA']
box_data_wrfchem = {
    'Historic': [[50, 90, 75, 95, 160] for _ in range(3)],
    'RCP4.5 NF': [[45, 85, 70, 90, 150] for _ in range(3)],
    'RCP8.5 NF': [[55, 95, 80, 100, 155] for _ in range(3)],
    'RCP4.5 FF': [[40, 80, 65, 85, 145] for _ in range(3)],
    'RCP8.5 FF': [[60, 100, 85, 105, 160] for _ in range(3)]
}

# Create WRFChem boxplots
ax1 = plt.subplot(gs[0, 0])
positions = np.arange(len(labels))
width = 0.15
offset = -0.3

for scenario, color in zip(box_data_wrfchem.keys(), colors):
    bp = ax1.boxplot([data[i] for i, _ in enumerate(labels)],
                    positions=positions + offset,
                    widths=0.15,
                    patch_artist=True,
                    medianprops=dict(color='black'),
                    flierprops=dict(marker='o', markersize=4))
    
    for box in bp['boxes']:
        box.set(facecolor=color)
    offset += 0.15

ax1.set_title('WRFChem', pad=10)
ax1.set_ylabel('MDA8 O₃ [μg/m³]')
ax1.set_ylim(0, 200)
ax1.set_xticks(positions)
ax1.set_xticklabels(labels)

# Create CAMx boxplots
ax2 = plt.subplot(gs[0, 1])
offset = -0.3

for scenario, color in zip(box_data_wrfchem.keys(), colors):
    bp = ax2.boxplot([data[i] for i, _ in enumerate(labels)],
                    positions=positions + offset,
                    widths=0.15,
                    patch_artist=True,
                    medianprops=dict(color='black'),
                    flierprops=dict(marker='o', markersize=4))
    
    for box in bp['boxes']:
        box.set(facecolor=color)
    offset += 0.15

ax2.set_title('CAMx', pad=10)
ax2.set_ylim(0, 200)
ax2.set_xticks(positions)
ax2.set_xticklabels(labels)

# Bar plot data
periods = ['Allyear', 'MAM', 'JJA', 'SON']
exceedances_wrfchem = {
    'Historic': [75, 28, 42, 3],
    'RCP4.5 NF': [70, 30, 32, 2],
    'RCP8.5 NF': [90, 35, 40, 4],
    'RCP4.5 FF': [20, 15, 12, 2],
    'RCP8.5 FF': [90, 38, 42, 5]
}

# Create WRFChem bar plot
ax3 = plt.subplot(gs[1, 0])
x = np.arange(len(periods))
width = 0.15
offset = -0.3

for scenario, color in zip(exceedances_wrfchem.keys(), colors):
    ax3.bar(x + offset, exceedances_wrfchem[scenario], width, color=color)
    offset += 0.15

ax3.set_ylim(0, 100)
ax3.set_xticks(x)
ax3.set_xticklabels(periods)
ax3.set_ylabel('Exceedances')

# Create CAMx bar plot (using similar data with slight variations)
ax4 = plt.subplot(gs[1, 1])
offset = -0.3

for scenario, color in zip(exceedances_wrfchem.keys(), colors):
    # Slightly modify data for CAMx to show variation
    values = [v * (1 + np.random.uniform(-0.1, 0.1)) for v in exceedances_wrfchem[scenario]]
    ax4.bar(x + offset, values, width, color=color)
    offset += 0.15

ax4.set_ylim(0, 100)
ax4.set_xticks(x)
ax4.set_xticklabels(periods)

# Add legend
handles = [plt.Rectangle((0,0),1,1, color=color) for color in colors]
fig.legend(handles, ['Historic', 'RCP4.5 NF', 'RCP8.5 NF', 'RCP4.5 FF', 'RCP8.5 FF'],
          loc='upper center', bbox_to_anchor=(0.5, 0.02), ncol=5)

# Adjust layout
plt.subplots_adjust(bottom=0.15)

# Save and show plot
plt.savefig('air_quality_comparison.png', dpi=300, bbox_inches='tight')
plt.savefig('air_quality_comparison.pdf', bbox_inches='tight')
plt.show()