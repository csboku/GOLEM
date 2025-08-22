# Bias Correction Thought Experiment

This project contains a complete thought and coding experiment designed to illustrate the strengths, weaknesses, and potential dangers of various statistical bias correction methods. Through a series of Python scripts, we simulate a realistic climate/environmental data scenario and apply a suite of correction techniques to demonstrate how the choice of method can have profound impacts on the results and their interpretation.

## 1. The Core Problem: Information Loss vs. Statistical Correction

In climate and environmental science, we often face a dilemma:
*   **High-Resolution Models:** Climate models can generate data on a fine grid (e.g., 1km), revealing complex local phenomena. However, these models are often biased compared to reality.
*   **Sparse Observations:** Real-world measurement stations provide accurate data but are sparsely located. They may not capture the fine-scale spatial details present in the model.

The core question this experiment addresses is: **What happens when we correct a high-resolution model (with complex spatial features) using data from sparse, point-based observations?**

Specifically, we test a scenario where our 1km model has a **bimodal distribution** (representing two common states), while our station data has a standard **unimodal distribution**. This sets up the central conflict: is the model's bimodality a real, high-resolution signal to be preserved, or an error to be removed?

## 2. Experimental Setup

### The Virtual World
- **A 90km x 90km Domain:** A virtual grid space for our experiment.
- **Two Model Grids:**
    - A coarse **9km** grid.
    - A fine **1km** grid.
- **Five Measurement Stations:** Five points within the domain that provide our "ground truth" observational data.

### The Simulated Datasets
- **Scenario:** We are measuring a fictional **"Pollutant X"** in parts-per-million (ppm). A value above **70 ppm** is considered a threshold exceedance.
- **9km Model (`ds_9km.nc`):** A coarse dataset with a simple, **Normal distribution** centered around 60 ppm. This serves as our "control" case.
- **1km Model (`ds_1km.nc`):** A high-resolution dataset with a **bimodal distribution** (with peaks at 55 and 65 ppm). This is our primary test case, representing a complex local process.
- **Station Data (`station_data.nc`):** A time series of 1000 measurements for each of the 5 stations. Each station has a unique, slightly **skewed unimodal distribution** also centered around 60 ppm, mimicking realistic measurement data.

## 3. Methodology

### 3.1. Bias Correction Methods Applied

We applied a comprehensive suite of seven different correction methods, ranging from simple to complex:

1.  **Delta Change:** Calculates the average difference between the model and all stations and adds this single value to every grid cell.
2.  **Scaling:** Calculates the average *ratio* between the model and all stations and multiplies every grid cell by this single value.
3.  **Variance Scaling:** Corrects both the mean and the standard deviation of the model data to match the stations.
4.  **Quantile Mapping (Empirical):** The most common and powerful method. It forces the model's entire distribution to match the station's distribution, regardless of their initial shapes.
5.  **Parametric Mapping (Normal):** Assumes both model and station data follow a Normal (bell curve) distribution and transforms the data accordingly.
6.  **Parametric Mapping (Gamma):** Assumes both follow a Gamma distribution (often better for pollutant data).
7.  **Spatial Delta:** A more advanced method. It calculates the delta (bias) at each station *individually* and then interpolates this bias across the grid, creating a spatially-variable correction.

### 3.2. Evaluation Techniques

We evaluated the performance of these methods using four different techniques:

1.  **Visual Analysis:** We generated a full suite of plots to visually inspect the results, including:
    - **Spatial Maps:** To see how the geographic patterns were affected.
    - **Histograms & PDFs:** To clearly see the shape of the data's distribution.
    - **ECDFs:** To compare the cumulative probability and tail behavior.
2.  **Quantitative Threshold Analysis:** We calculated the percentage of the domain area exceeding the 70 ppm threshold for each method.
3.  **Temporal Analysis:** We analyzed the corrected time series at a single grid point to see how the methods affected the prediction of "high pollution days".
4.  **Leave-One-Out Cross-Validation:** The most rigorous test. We held out each station one-by-one, trained the correction on the remaining four, and calculated the Root Mean Square Error (RMSE) of the model's prediction at the held-out station's location. The method with the lowest average RMSE is the most predictively accurate.

## 4. How to Run the Experiment

To replicate this entire experiment, follow these steps.

### Prerequisites
- A Python environment (e.g., `conda` or `venv`).
- The necessary libraries installed. You can use the provided `cs-py` mamba environment or install them via pip:
  ```bash
  pip install numpy xarray scipy pandas matplotlib seaborn
  ```

### Execution
Run the scripts in the following order. A convenience command to run everything is provided below.

1.  **`simulation.py`**: Generates the three base datasets (`ds_1km.nc`, `ds_9km.nc`, `station_data.nc`).
2.  **`bias_correction.py`**: Takes the base datasets and applies all seven correction methods, creating a new corrected dataset for each.
3.  **`visualization.py`**: Generates all plots (`.png` files) for visual analysis.
4.  **`summary.py`**: Calculates the quantitative threshold statistics and prints a summary table.
5.  **`temporal_analysis.py`**: Performs the time series analysis at a single point.
6.  **`cross_validation.py`**: Runs the final, definitive cross-validation test and prints the RMSE ranking.

**Convenience Command:**
```bash
python simulation.py && \
python bias_correction.py && \
python visualization.py && \
python summary.py && \
python temporal_analysis.py && \
python cross_validation.py
```

## 5. Key Results and Conclusions

The cross-validation provided the most definitive ranking of the methods' predictive skill:

| Method             | Average RMSE |
|--------------------|--------------|
| **Variance**       | **7.37**     |
| **Parametric**     | **7.37**     |
| Original           | 8.18         |
| Parametric Gamma   | 8.32         |
| Delta              | 9.21         |
| Scaling            | 9.53         |
| Spatial Delta      | 11.19        |
| Qm                 | 11.49        |

### The Grand Takeaway

1.  **The "Best" Methods Aren't The Most Complex:** The clear winners were **Variance Scaling** and **Parametric Mapping (Normal)**. They provided the most accurate predictions because they corrected both the mean and the variance without being overly aggressive.

2.  **The Most "Powerful" Method Was The Worst:** **Quantile Mapping (QM)**, which is designed to perfectly match the station distribution, performed the worst in the cross-validation. Our visual analysis proved *why*: it completely erased the bimodal signal in the 1km data. This experiment demonstrates that while QM is a powerful tool, it can be dangerously misleading, destroying real information and leading to poor predictive performance.

3.  **Simple Isn't Always Better:** The simplest methods, **Delta** and **Scaling**, also performed poorly, proving that only correcting the mean is insufficient.

4.  **Scientific Judgment is Irreplaceable:** This experiment proves that bias correction is not a purely statistical exercise. A scientist must use their judgment. Seeing the bimodal distribution and understanding the limitations of the station network is critical. Blindly applying the most "advanced" method (like Quantile Mapping) can lead to incorrect scientific conclusions and poor predictions. The best methods struck a balance between statistical correction and preservation of the model's underlying structure.

## 6. File Descriptions

- **`config.py`**: Main configuration file for scenario parameters (variable name, unit, threshold).
- **`simulation.py`**: Generates all the base model and station datasets.
- **`bias_correction.py`**: Contains the implementation of all seven bias correction methods.
- **`visualization.py`**: Generates all plots (histograms, spatial maps, PDFs, ECDFs).
- **`summary.py`**: Calculates and prints the quantitative summary of threshold exceedances.
- **`temporal_analysis.py`**: Performs the time series analysis at a single point.
- **`cross_validation.py`**: Performs the leave-one-out cross-validation to objectively rank the methods.
- **`*.nc`**: NetCDF files containing the data for the models, stations, and all corrected outputs.
- **`*.png`**: Image files containing all the generated plots.
- **`README.md`**: This documentation file.
