"""
Calculates and prints a quantitative summary of the bias correction experiment results.
"""

import xarray as xr
import pandas as pd
import config

def analyze_dataset(data):
    """Calculates key metrics for a single dataset."""
    mean_val = data.mean().item()
    std_val = data.std().item()
    
    # Calculate the percentage of area exceeding the threshold
    total_cells = data.size
    exceeding_cells = (data > config.THRESHOLD_VALUE).sum().item()
    exceedance_percentage = (exceeding_cells / total_cells) * 100
    
    return {
        "Mean (ppm)": f"{mean_val:.2f}",
        "Std Dev (ppm)": f"{std_val:.2f}",
        f"% Area > {config.THRESHOLD_VALUE} ppm": f"{exceedance_percentage:.2f}%"
    }

def main():
    """Main function to generate and print the summary."""
    
    methods = ["scaling", "delta", "variance", "parametric", "parametric_gamma", "qm", "spatial_delta"]
    scenarios = {"1km": "bimodal_data", "9km": "normal_data"}
    
    all_results = []

    for scenario_name, data_var_name in scenarios.items():
        # Analyze original data
        original_data = xr.open_dataset(f"ds_{scenario_name}.nc")[config.VARIABLE_NAME]
        original_metrics = analyze_dataset(original_data)
        original_metrics["Scenario"] = scenario_name
        original_metrics["Method"] = "Original"
        all_results.append(original_metrics)

        # Analyze corrected data
        for method in methods:
            try:
                file_path = f"corrected_ds_{scenario_name}_{method}.nc"
                corrected_data = xr.open_dataset(file_path)[config.VARIABLE_NAME]
                metrics = analyze_dataset(corrected_data)
                metrics["Scenario"] = scenario_name
                metrics["Method"] = method.replace("_", " ").title()
                all_results.append(metrics)
            except FileNotFoundError:
                print(f"Warning: Could not find file {file_path}. Skipping.")

    # Create and print a pandas DataFrame for a clean table
    df = pd.DataFrame(all_results)
    df = df.set_index(["Scenario", "Method"])
    
    # Reorder columns for clarity
    df = df[["Mean (ppm)", "Std Dev (ppm)", f"% Area > {config.THRESHOLD_VALUE} ppm"]]

    print("\n" + "="*80)
    print("                Quantitative Summary of Bias Correction Results")
    print("="*80)
    print(df.to_string())
    print("="*80 + "\n")

if __name__ == "__main__":
    main()
