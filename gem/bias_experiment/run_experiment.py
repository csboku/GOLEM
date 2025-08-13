"""A master script to run the entire bias correction experiment for multiple
scenarios with a varying number of measurement stations.
"""
import os
import subprocess
import numpy as np
import json

# --- Experiment Scenarios ---
SCENARIOS = {
    "3_stations": 3,
    "10_stations": 10,
    "25_stations": 25,
}

def generate_station_locations(n_stations):
    """Generates a dictionary of plausible, semi-random station locations."""
    locations = {}
    # Use a seed for reproducibility
    np.random.seed(42)
    for i in range(n_stations):
        station_name = f"station_{i+1}"
        # Generate locations within a central box to avoid edge effects
        x = np.random.randint(10000, 80000)
        y = np.random.randint(10000, 80000)
        locations[station_name] = (int(x), int(y))
    return locations

def write_config(n_stations):
    """Writes a new config.py file for a given scenario."""
    locations = generate_station_locations(n_stations)
    config_content = f"""# config.py (auto-generated)

VARIABLE_NAME = \"Pollutant X\"
VARIABLE_UNIT = \"ppm\"
THRESHOLD_VALUE = 65

X_MIN = 0
X_MAX = 90000
Y_MIN = 0
Y_MAX = 90000

RESOLUTION_9KM = 9000
RESOLUTION_1KM = 1000

N_STATIONS = {n_stations}
STATION_LOCATIONS = {json.dumps(locations, indent=4)}
"""
    with open("config.py", "w") as f:
        f.write(config_content)
    print(f"Generated config.py for {n_stations} stations.")

def run_command(command):
    """Runs a shell command and checks for errors."""
    print(f"--- Running: {command} ---")
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print("!!! ERROR !!!")
        print(result.stdout)
        print(result.stderr)
        raise RuntimeError(f"Command failed: {command}")
    print(result.stdout)
    print(result.stderr)

def main():
    """Main function to orchestrate the entire experiment."""
    original_dir = os.getcwd()
    
    for scenario_name, n_stations in SCENARIOS.items():
        print(f"\n{'='*80}\nRunning Scenario: {scenario_name}\n{'='*80}")
        
        # 1. Create the scenario-specific config file
        write_config(n_stations)
        
        # 2. Run the full data pipeline
        run_command("python simulation.py")
        run_command("python bias_correction.py")
        
        # 3. Create the output directory for this scenario
        output_dir = os.path.join(original_dir, "web", "data", scenario_name)
        os.makedirs(output_dir, exist_ok=True)
        
        # 4. Run the export scripts, slightly modified to output to the correct directory
        # We will create temporary, modified export scripts for this
        
        # Modify export_for_web.py
        with open("export_for_web.py", "r") as f:
            export_script = f.read()
        modified_export = export_script.replace('output_dir = "web/data"', f'output_dir = "{output_dir}"')
        with open("temp_export.py", "w") as f:
            f.write(modified_export)
        run_command("python temp_export.py")

        # Modify export_final_scores.py
        with open("export_final_scores.py", "r") as f:
            scores_script = f.read()
        modified_scores = scores_script.replace('filepath = os.path.join("web/data", "scores.json")', f'filepath = os.path.join("{output_dir}", "scores.json")')
        with open("temp_scores.py", "w") as f:
            f.write(modified_scores)
        run_command("python temp_scores.py")

        # Clean up temporary scripts
        os.remove("temp_export.py")
        os.remove("temp_scores.py")

    print(f"\n{'='*80}\nAll scenarios completed successfully.\n{'='*80}")

if __name__ == "__main__":
    main()
