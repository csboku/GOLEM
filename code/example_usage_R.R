# Example usage of GOLEM R library
source("GOLEM_R.R")

# Example 1: Data Processing
cat("Example 1: Data Processing\n")

# Create mock data with NA values
mock_data <- data.frame(
  station = paste0("Station_", 1:10),
  value1 = c(120, 130, NA, 140, 150, NA, NA, 120, 110, 125),
  value2 = c(110, NA, 125, 135, NA, 145, 150, NA, 105, 115),
  altitude = c(800, 1200, 1800, 900, 1600, 750, 1100, 2000, 950, 1400)
)

# Find NA columns
na_counts <- na_count(mock_data)
cat("NA counts by column:\n")
print(na_counts)

# Filter columns with too many NAs
filtered_data <- filter_na(mock_data, na_threshold = 2)
cat("Filtered data (columns with < 2 NAs):\n")
print(filtered_data)

# Filter by altitude
low_alt_data <- filter_by_altitude(mock_data, max_alt = 1500)
cat("Stations below 1500m altitude:\n")
print(low_alt_data$station)

# Example 2: Visualization
cat("\nExample 2: Visualization\n")

# Create some mock data for visualization
set.seed(123)
data_list <- list(
  Measurements = rnorm(100, mean = 100, sd = 20),
  WRF = rnorm(100, mean = 105, sd = 15),
  CAMx = rnorm(100, mean = 95, sd = 18)
)

# Create a density plot
cat("Creating density plot...\n")
density_plot <- plot_density_comparison(
  data_list = data_list,
  title = "O3 Concentration Distribution",
  x_label = "Concentration [μg/m³]",
  colors = c("#1B9E77", "#D95F02", "#7570B3")
)
cat("Density plot created (not shown in console output)\n")

# Create a boxplot
cat("Creating boxplot...\n")
boxplot <- plot_boxplot_comparison(
  data_list = data_list,
  title = "Model Comparison",
  y_label = "O3 Concentration [μg/m³]",
  colors = c("#1B9E77", "#D95F02", "#7570B3")
)
cat("Boxplot created (not shown in console output)\n")

# Example 3: Statistical Analysis
cat("\nExample 3: Statistical Analysis\n")

# Calculate exceedances
exceedances <- calc_exceedances(unlist(data_list["WRF"]), threshold = 120)
exceed_count <- sum(exceedances)
cat("Number of exceedances:", exceed_count, "out of", length(exceedances), "\n")

# Calculate stats metrics
metrics <- calc_stats_metrics(data_list$Measurements, data_list$WRF)
cat("Statistical metrics:\n")
print(data.frame(Metric = names(metrics), Value = unlist(metrics)))

# Example 4: Compare multiple models
cat("\nExample 4: Model Comparison\n")

# Compare all models against measurements
comparison <- compare_models(data_list$Measurements, 
                            list(WRF = data_list$WRF, CAMx = data_list$CAMx))
cat("Model comparison:\n")
print(comparison)

# To save the plots, uncomment these lines:
# pdf("density_plot.pdf")
# print(density_plot)
# dev.off()
# 
# pdf("boxplot.pdf")
# print(boxplot)
# dev.off()

cat("\nGOLEM R examples completed\n")