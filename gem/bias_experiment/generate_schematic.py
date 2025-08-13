"""
Generates a schematic diagram to illustrate the concept of Quantile Mapping.
"""
import numpy as np
import matplotlib.pyplot as plt
from scipy.stats import norm

def generate_qm_schematic():
    """Creates and saves the Quantile Mapping schematic figure."""
    
    # Define two different normal distributions
    model_dist = norm(loc=5, scale=1.5)
    obs_dist = norm(loc=8, scale=2.0)
    
    # Create x-values for plotting the PDFs
    x = np.linspace(-2, 15, 500)
    
    # Pick a value from the model distribution to transform
    model_value = 4.0
    
    # Find the percentile (CDF value) of this value in the model's distribution
    percentile = model_dist.cdf(model_value)
    
    # Find the value in the observation's distribution that corresponds to that same percentile
    corrected_value = obs_dist.ppf(percentile)

    # --- Create the Plot ---
    plt.style.use('seaborn-v0_8-whitegrid')
    fig, ax = plt.subplots(figsize=(10, 6))

    # Plot the two PDF curves
    ax.plot(x, model_dist.pdf(x), color='red', linewidth=2, label='Biased Model PDF')
    ax.plot(x, obs_dist.pdf(x), color='green', linewidth=2, label='Observed PDF (Truth)')
    
    # Draw the mapping lines
    # 1. From model value up to the percentile
    ax.plot([model_value, model_value], [0, model_dist.pdf(model_value)], color='red', linestyle='--')
    
    # 2. Horizontal line representing the percentile transfer
    ax.annotate("", xy=(corrected_value, obs_dist.pdf(corrected_value)), xytext=(model_value, model_dist.pdf(model_value)),
                arrowprops=dict(arrowstyle="->", color='black', lw=1.5, connectionstyle="arc3,rad=0.2"))
    
    # 3. From the percentile down to the corrected value
    ax.plot([corrected_value, corrected_value], [0, obs_dist.pdf(corrected_value)], color='green', linestyle='--')

    # Add text and labels
    ax.text(model_value - 0.5, -0.015, f'{model_value:.1f}', color='red', ha='center')
    ax.text(corrected_value, -0.015, f'{corrected_value:.1f}', color='green', ha='center')
    ax.text((model_value + corrected_value) / 2, model_dist.pdf(model_value) * 1.1,
             f'CDF = {percentile:.2f}', ha='center', fontsize=10,
             bbox=dict(facecolor='white', alpha=0.8, edgecolor='none'))

    ax.set_title('The Concept of Quantile Mapping', fontsize=16)
    ax.set_xlabel('Value (e.g., Pollutant X in ppm)')
    ax.set_ylabel('Probability Density')
    ax.legend()
    ax.set_ylim(bottom=0)

    plt.tight_layout()
    plt.savefig('qm_schematic.png', dpi=300)
    print("Successfully generated qm_schematic.png")

if __name__ == "__main__":
    generate_qm_schematic()
