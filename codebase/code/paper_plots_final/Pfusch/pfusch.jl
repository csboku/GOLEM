using CairoMakie
using Random
using Statistics

# Set random seed for reproducibility
Random.seed!(42)

# Generate sample data (replace with your actual data)
function generate_box_data(base_mean)
    return [base_mean .+ randn(100) .* 15 for _ in 1:5]
end

# Data setup
periods = ["Allyear", "MAM", "JJA"]
models = ["Historic", "RCP4.5 NF", "RCP8.5 NF", "RCP4.5 FF", "RCP8.5 FF"]
colors = [:teal, :orange, :red, :brown4, :brown8]

# Exceedance data
exceedances_wrfchem = Dict(
    "Allyear" => [75, 70, 90, 20, 90],
    "MAM" => [28, 30, 35, 15, 38],
    "JJA" => [42, 32, 40, 12, 42],
    "SON" => [3, 2, 4, 2, 5]
)

exceedances_camx = Dict(
    "Allyear" => [78, 70, 90, 18, 92],
    "MAM" => [28, 26, 32, 16, 36],
    "JJA" => [38, 30, 40, 15, 40],
    "SON" => [4, 3, 5, 2, 6]
)

# Create figure
fig = Figure(size=(1200, 800))

# Create GridLayout
gl = fig[1, 1] = GridLayout()

# Create axes
ax_wrfchem_box = Axis(gl[1, 1],
    title="WRFChem",
    ylabel="MDA8 O₃ [μg/m³]",
    xticks=(1:3, periods),
    limits=(0.5, 3.5, 0, 200)
)

ax_camx_box = Axis(gl[1, 2],
    title="CAMx",
    xticks=(1:3, periods),
    limits=(0.5, 3.5, 0, 200)
)

ax_wrfchem_bar = Axis(gl[2, 1],
    ylabel="Exceedances",
    xticks=(1:4, keys(exceedances_wrfchem)),
    limits=(0.5, 4.5, 0, 100)
)

ax_camx_bar = Axis(gl[2, 2],
    xticks=(1:4, keys(exceedances_camx)),
    limits=(0.5, 4.5, 0, 100)
)

# Plot boxplots
for (i, period) in enumerate(periods)
    data_wrfchem = generate_box_data(90)
    data_camx = generate_box_data(90)
    
    for (j, (data_w, data_c)) in enumerate(zip(data_wrfchem, data_camx))
        boxplot!(ax_wrfchem_box, fill(i - 0.3 + j * 0.15, length(data_w)), data_w,
            width=0.1,
            color=(colors[j], 0.6),
            whiskerwidth=0.1)
            
        boxplot!(ax_camx_box, fill(i - 0.3 + j * 0.15, length(data_c)), data_c,
            width=0.1,
            color=(colors[j], 0.6),
            whiskerwidth=0.1)
    end
end

# Plot bar charts
bar_width = 0.15
for (i, model) in enumerate(models)
    # WRFChem bars
    x_positions = 1:length(exceedances_wrfchem)
    values = [exceedances_wrfchem[period][i] for period in keys(exceedances_wrfchem)]
    barplot!(ax_wrfchem_bar, x_positions .+ (i-3)*bar_width, values,
        width=bar_width,
        color=(colors[i], 0.8))
        
    # CAMx bars
    values_camx = [exceedances_camx[period][i] for period in keys(exceedances_camx)]
    barplot!(ax_camx_bar, x_positions .+ (i-3)*bar_width, values_camx,
        width=bar_width,
        color=(colors[i], 0.8))
end

# Add legend
Legend(fig[3, 1:2], 
    [PolyElement(color=(color, 0.6)) for color in colors],
    models,
    orientation=:horizontal)

# Adjust layout
rowgap!(gl, 10)
colgap!(gl, 10)

# Save the figure
save("air_quality_comparison.png", fig, px_per_unit=2)
save("air_quality_comparison.pdf", fig)
save("air_quality_comparison.svg", fig)