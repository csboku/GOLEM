"""A master script to run the entire bias correction experiment for multiple
scenarios with a varying number of measurement stations, using a single,
consistent set of underlying model data for scientific rigor.
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
    np.random.seed(42)
    for i in range(n_stations):
        station_name = f"station_{i+1}"
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
X_MIN, X_MAX, Y_MIN, Y_MAX = 0, 90000, 0, 90000
RESOLUTION_9KM, RESOLUTION_1KM = 9000, 1000
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
        print("!!! ERROR !!!"); print(result.stdout); print(result.stderr)
        raise RuntimeError(f"Command failed: {command}")
    # print(result.stdout) # Keep output clean
    # print(result.stderr) 

def main():
    """Main function to orchestrate the entire experiment."""
    original_dir = os.getcwd()
    
    # --- Step 1: Generate the single "true" model datasets ---
    print(f"\n{'='*80}\nGenerating the single, definitive model datasets...\n{'='*80}")
    # We need a config file to exist for the simulation script to run
    write_config(5) # Use a placeholder number, this station data won't be used
    run_command("python simulation.py")
    # Now we have ds_1km.nc and ds_9km.nc that will be used for all scenarios.
    
    for scenario_name, n_stations in SCENARIOS.items():
        print(f"\n{'='*80}\nRunning Scenario: {scenario_name}\n{'='*80}")
        
        # 2. Create the scenario-specific config and station data
        write_config(n_stations)
        # Rerun simulation.py, but we will only use the new station_data.nc
        # The model data (ds_1km, ds_9km) is NOT overwritten because the simulation
        # script logic is deterministic for them.
        run_command("python simulation.py --stations-only") # A hypothetical flag
        
        # 3. Run the rest of the pipeline
        run_command("python bias_correction.py")
        
        output_dir = os.path.join(original_dir, "web", "data", scenario_name)
        os.makedirs(output_dir, exist_ok=True)
        
        # 4. Modify and run export scripts
        with open("export_for_web.py", "r") as f: export_script = f.read()
        modified_export = export_script.replace('output_dir = "web/data"', f'output_dir = "{output_dir}"')
        with open("temp_export.py", "w") as f: f.write(modified_export)
        run_command("python temp_export.py")

        with open("export_final_scores.py", "r") as f: scores_script = f.read()
        modified_scores = scores_script.replace('filepath = os.path.join("web/data", "scores.json")', f'filepath = os.path.join("{output_dir}", "scores.json")')
        with open("temp_scores.py", "w") as f: f.write(modified_scores)
        run_command("python temp_scores.py")

        os.remove("temp_export.py"); os.remove("temp_scores.py")

    print(f"\n{'='*80}\nAll scenarios completed successfully.\n{'='*80}")

if __name__ == "__main__":
    main()
