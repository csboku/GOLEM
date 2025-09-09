import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib


matplotlib.use('Agg')  # Use a non-GUI backend
# Load the data
file_path = './fire_data_corr.csv'
fire_data = pd.read_csv(file_path)

# Prepare data for visualization
class_changes = fire_data[['ffmc_class', 'ffmc_adj_class']]

# Create a crosstab for heatmap
heatmap_data = pd.crosstab(class_changes['ffmc_class'], class_changes['ffmc_adj_class'])

# Create barplot data for the distribution of original and adjusted classes
original_class_counts = class_changes['ffmc_class'].value_counts().sort_index()
adjusted_class_counts = class_changes['ffmc_adj_class'].value_counts().sort_index()

# Plot heatmap of class changes
plt.figure(figsize=(8, 5))
sns.heatmap(heatmap_data, annot=True, cmap="YlGnBu", fmt="d")
plt.title("FFMC Klassenänderungen")
plt.xlabel("Angepasste Klasse")
plt.ylabel("Originale Klasse")
plt.savefig("heatmap_ffmc_class_changes.png", dpi=160)




# Plot barplot comparison
plt.figure(figsize=(8, 5))
bar_width = 0.35
indices = original_class_counts.index

plt.bar(indices - bar_width/2, original_class_counts, bar_width, label='Originale Klasse')
plt.bar(indices + bar_width/2, adjusted_class_counts, bar_width, label='Angepasste Klasse')

plt.xlabel("FFMC Klasse", fontsize=16)
plt.ylabel("Anzahl", fontsize=16)
plt.title("Vergleich der FFMC-Klassenzahlen", fontsize=18)
plt.xticks(indices)
plt.legend()
plt.savefig("barplot_ffmc_class_comparison.png", dpi=120)

# Calculate class changes
class_changes_diff = class_changes['ffmc_adj_class'] - class_changes['ffmc_class']

# Count occurrences of class changes from -1 to 3
class_change_counts_corrected = class_changes_diff.value_counts().reindex(range(-1, 4), fill_value=0)


# Plot corrected barplot of class changes with custom color scheme
color_scheme =sns.color_palette("coolwarm", 6)[1:6]
plt.figure(figsize=(8, 5))
class_change_counts_corrected.plot(kind='bar', color=color_scheme)
plt.xticks(range(5), ['-1', '0', '1', '2', '3'], rotation=0)
plt.xlabel("Klassenänderung (Angepasst - Original)", fontsize=16)
plt.ylabel("Anzahl", fontsize=16)
plt.title("FFMC Klassenänderung", fontsize=18)
plt.savefig("barplot_ffmc_class_changes.png", dpi=120)