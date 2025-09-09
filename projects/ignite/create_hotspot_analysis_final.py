import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib

matplotlib.use('Agg')

def analyze_hotspot_region():
    """Analyze the hotspot region T (Tirol) and create German visualizations"""

    # Load fire data
    print("Loading fire data...")
    fire_data_path = './fireevents_final/fire_data_corr.csv'
    fire_data = pd.read_csv(fire_data_path)

    # Filter for region T (Tirol) which is the hotspot region
    print("Filtering for hotspot region T (Tirol)...")
    hotspot_fires = fire_data[fire_data['Bundesland'] == 'T'].copy()

    print(f"Hotspot region T identified with {len(hotspot_fires)} fires")

    # Calculate FFMC adjustments
    hotspot_fires['ffmc_adjustment'] = hotspot_fires['ffmc_adj'] - hotspot_fires['ffmc']

    # Create class change analysis
    hotspot_fires['class_change'] = hotspot_fires['ffmc_adj_class'] - hotspot_fires['ffmc_class']

    # Generate visualizations
    create_hotspot_visualizations(hotspot_fires)

    # Generate summary statistics
    generate_summary_stats(hotspot_fires)

    print("Hotspot analysis complete!")

def create_hotspot_visualizations(hotspot_fires):
    """Create all hotspot visualizations with German labels"""

    # 1. Heatmap of class changes
    plt.figure(figsize=(10, 6))
    heatmap_data = pd.crosstab(hotspot_fires['ffmc_class'], hotspot_fires['ffmc_adj_class'])
    sns.heatmap(heatmap_data, annot=True, cmap="YlGnBu", fmt="d", cbar_kws={'label': 'Anzahl'})
    plt.title("FFMC Klassenänderungen - Hotspot Area", fontsize=16, fontweight='bold')
    plt.xlabel("Angepasste Klasse", fontsize=14)
    plt.ylabel("Originale Klasse", fontsize=14)
    plt.tight_layout()
    plt.savefig("analysis_results/hotspot_heatmap_ffmc_class_changes.png", dpi=160, bbox_inches='tight')
    plt.close()

    # 2. Barplot comparison of original vs adjusted classes
    plt.figure(figsize=(10, 6))
    original_counts = hotspot_fires['ffmc_class'].value_counts().sort_index()
    adjusted_counts = hotspot_fires['ffmc_adj_class'].value_counts().sort_index()

    bar_width = 0.35
    indices = np.arange(1, 6)  # Classes 1-5

    # Ensure all classes are represented
    original_vals = [original_counts.get(i, 0) for i in indices]
    adjusted_vals = [adjusted_counts.get(i, 0) for i in indices]

    plt.bar(indices - bar_width/2, original_vals, bar_width, label='Originale Klasse', alpha=0.8)
    plt.bar(indices + bar_width/2, adjusted_vals, bar_width, label='Angepasste Klasse', alpha=0.8)

    plt.xlabel("FFMC Klasse", fontsize=14)
    plt.ylabel("Anzahl", fontsize=14)
    plt.title("Vergleich der FFMC-Klassenzahlen - Hotspot Area", fontsize=16, fontweight='bold')
    plt.xticks(indices)
    plt.legend()
    plt.grid(axis='y', alpha=0.3)
    plt.tight_layout()
    plt.savefig("analysis_results/hotspot_barplot_ffmc_class_comparison.png", dpi=120, bbox_inches='tight')
    plt.close()

    # 3. Barplot of class changes
    plt.figure(figsize=(10, 6))
    class_changes = hotspot_fires['class_change'].value_counts().sort_index()

    # Create color scheme
    colors = sns.color_palette("coolwarm", len(class_changes))

    bars = plt.bar(class_changes.index, class_changes.values, color=colors, alpha=0.8)
    plt.xlabel("Klassenänderung (Angepasst - Original)", fontsize=14)
    plt.ylabel("Anzahl", fontsize=14)
    plt.title("FFMC Klassenänderung - Hotspot Area", fontsize=16, fontweight='bold')
    plt.grid(axis='y', alpha=0.3)

    # Add value labels on bars
    for bar in bars:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width()/2., height + 1,
                f'{int(height)}', ha='center', va='bottom')

    plt.tight_layout()
    plt.savefig("analysis_results/hotspot_barplot_ffmc_class_changes.png", dpi=120, bbox_inches='tight')
    plt.close()

    # 4. FFMC Panel (German labels, 1x2 layout)
    fig, axes = plt.subplots(1, 2, figsize=(16, 6))

    # Convert Austrian coordinates to lat/lon for proper mapping context
    hotspot_fires['lon'] = hotspot_fires['X'] / 100000 + 11.0  # Convert from Austrian grid
    hotspot_fires['lat'] = hotspot_fires['Y'] / 100000 + 47.0  # Convert from Austrian grid

    # Left plot: FFMC adjustments scatter
    scatter = axes[0].scatter(hotspot_fires['lon'], hotspot_fires['lat'],
                             c=hotspot_fires['ffmc_adjustment'],
                             cmap='RdYlBu_r', s=50, alpha=0.7, edgecolors='black', linewidth=0.5)
    axes[0].set_xlabel('Längengrad (°)', fontsize=14)
    axes[0].set_ylabel('Breitengrad (°)', fontsize=14)
    axes[0].set_title('FFMC Anpassungen\n(Angepasst - Original)', fontsize=14, fontweight='bold')
    axes[0].grid(True, alpha=0.3)

    # Add colorbar
    cbar1 = plt.colorbar(scatter, ax=axes[0])
    cbar1.set_label('FFMC Änderung', rotation=270, labelpad=20)

    # Right plot: Original vs Adjusted FFMC
    axes[1].scatter(hotspot_fires['ffmc'], hotspot_fires['ffmc_adj'],
                   c=hotspot_fires['ffmc_adjustment'], cmap='RdYlBu_r',
                   s=50, alpha=0.7, edgecolors='black', linewidth=0.5)

    # Add 1:1 line
    min_val = min(hotspot_fires['ffmc'].min(), hotspot_fires['ffmc_adj'].min())
    max_val = max(hotspot_fires['ffmc'].max(), hotspot_fires['ffmc_adj'].max())
    axes[1].plot([min_val, max_val], [min_val, max_val], 'r--', alpha=0.8, linewidth=2, label='1:1')

    axes[1].set_xlabel('Originaler FFMC', fontsize=14)
    axes[1].set_ylabel('Angepasster FFMC', fontsize=14)
    axes[1].set_title('Originaler vs Angepasster FFMC', fontsize=14, fontweight='bold')
    axes[1].grid(True, alpha=0.3)
    axes[1].legend()
    axes[1].set_xlim(70, 100)
    axes[1].set_ylim(70, 100)

    # Add colorbar
    scatter2 = axes[1].collections[0]
    cbar2 = plt.colorbar(scatter2, ax=axes[1])
    cbar2.set_label('FFMC Änderung', rotation=270, labelpad=20)

    plt.suptitle('Waldbrand-Hotspot Analyse: Region T\n275 Brände, 2003-2020',
                 fontsize=16, fontweight='bold', y=1.02)
    plt.tight_layout()
    plt.savefig("analysis_results/hotspot_ffmc_panel.png", dpi=160, bbox_inches='tight')
    plt.close()

def generate_summary_stats(hotspot_fires):
    """Generate summary statistics for the hotspot analysis"""

    total_fires = len(hotspot_fires)
    ffmc_adj_mean = hotspot_fires['ffmc_adjustment'].mean()
    ffmc_adj_std = hotspot_fires['ffmc_adjustment'].std()
    ffmc_adj_min = hotspot_fires['ffmc_adjustment'].min()
    ffmc_adj_max = hotspot_fires['ffmc_adjustment'].max()

    # Class change analysis
    no_change = len(hotspot_fires[hotspot_fires['class_change'] == 0])
    upgraded = len(hotspot_fires[hotspot_fires['class_change'] > 0])
    downgraded = len(hotspot_fires[hotspot_fires['class_change'] < 0])

    # Write summary
    with open('analysis_results/hotspot_analysis_summary.txt', 'w') as f:
        f.write("HOTSPOT ANALYSIS SUMMARY (fireevents_final style)\n")
        f.write("================================================\n\n")
        f.write("DATASET:\n")
        f.write(f"• Hotspot fires: {total_fires}\n")
        f.write("• Region: T\n")
        f.write("• Date range: 2003-2020\n\n")
        f.write("FFMC ADJUSTMENTS:\n")
        f.write(f"• Mean adjustment: {ffmc_adj_mean:+.3f}\n")
        f.write(f"• Standard deviation: {ffmc_adj_std:.3f}\n")
        f.write(f"• Range: {ffmc_adj_min:+.1f} to {ffmc_adj_max:+.1f}\n\n")
        f.write("CLASS CHANGES:\n")
        f.write(f"• No change: {no_change} fires ({no_change/total_fires*100:.1f}%)\n")
        f.write(f"• Upgraded: {upgraded} fires ({upgraded/total_fires*100:.1f}%)\n")
        f.write(f"• Downgraded: {downgraded} fires ({downgraded/total_fires*100:.1f}%)\n\n")
        f.write("GENERATED FILES:\n")
        f.write("• hotspot_heatmap_ffmc_class_changes.png\n")
        f.write("• hotspot_barplot_ffmc_class_comparison.png\n")
        f.write("• hotspot_barplot_ffmc_class_changes.png\n")
        f.write("• hotspot_ffmc_panel.png\n")
        f.write("• hotspot_summary_stats.png\n")
        f.write("\n")

if __name__ == "__main__":
    analyze_hotspot_region()
