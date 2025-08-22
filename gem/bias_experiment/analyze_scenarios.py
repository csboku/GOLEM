"""
Analyzes the results of the multi-station-scenario experiment and generates
a final summary plot and table.
"""
import json
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def analyze_scenarios():
    """Loads all scenario results and creates a summary plot and table."""
    
    scenarios = ["3_stations", "10_stations", "25_stations"]
    data_dir = os.path.join("web", "data")
    
    all_results = []

    for scenario in scenarios:
        n_stations = int(scenario.split('_')[0])
        scores_file = os.path.join(data_dir, scenario, "scores.json")
        
        with open(scores_file, 'r') as f:
            scores = json.load(f)
            
            for method, rmse in scores.items():
                if method == "Stations (Observed)": continue
                all_results.append({
                    "Number of Stations": n_stations,
                    "Method": method,
                    "RMSE": float(rmse) if rmse != "N/A" else None
                })

    df = pd.DataFrame(all_results).dropna()
    
    # --- Create the Final Plot ---
    plt.style.use('seaborn-v0_8-whitegrid')
    fig, ax = plt.subplots(figsize=(12, 8))
    
    # Use seaborn for a clean line plot with markers
    sns.lineplot(data=df, x="Number of Stations", y="RMSE", hue="Method", style="Method", markers=True, dashes=False, ax=ax, linewidth=2.5, markersize=10)
    
    ax.set_title('Bias Correction Performance vs. Station Network Density', fontsize=18, weight='bold')
    ax.set_xlabel('Number of Measurement Stations in Network', fontsize=12)
    ax.set_ylabel('Average RMSE (ppm) at Unobserved Locations', fontsize=12)
    ax.grid(True, which='both', linestyle='--', linewidth=0.5)
    ax.set_xticks([3, 10, 25]) # Ensure we have ticks for our scenarios
    
    # Improve legend
    plt.legend(title='Correction Method', bbox_to_anchor=(1.05, 1), loc='upper left')
    
    plt.tight_layout()
    plt.savefig('scenario_analysis.png', dpi=300)
    print("Successfully generated the final analysis plot: scenario_analysis.png")

    # --- Print Final Summary Table ---
    summary_table = df.pivot(index="Method", columns="Number of Stations", values="RMSE")
    print("\n" + "="*80)
    print("        Definitive Cross-Validation Results (RMSE vs. Number of Stations)")
    print("="*80)
    print(summary_table.to_string())
    print("="*80 + "\n")


if __name__ == "__main__":
    analyze_scenarios()
