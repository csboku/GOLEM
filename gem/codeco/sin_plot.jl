using Plots

# Generate x values from 0 to 2π
x = 0:0.1:2π

# Calculate corresponding y values (sin(x))
y = sin.(x)

# Create the plot
plot(x, y, label="sin(x)", title="Sine Wave Plot", xlabel="x", ylabel="sin(x)")

# Save the plot to a file
savefig("sin_plot.png")
