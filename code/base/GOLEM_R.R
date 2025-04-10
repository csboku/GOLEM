#' GOLEM R Library
#' 
#' This script provides a collection of R functions for environmental data analysis
#' organized in a functional approach. Functions are grouped into modules for
#' data processing, visualization, spatial analysis, and statistical analysis.
#' 
#' @author GOLEM Team

# Load required libraries
required_packages <- c("tidyverse", "sf", "velox", "raster", "ncdf4", "lubridate", "terra")

# Check and install packages if needed
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(paste("Package", pkg, "not found. Please install it with install.packages('", pkg, "')"))
  }
}

#####################################
# Data Processing Module
#####################################

#' Remove NA values from columns or rows
#' 
#' @param data A dataframe or matrix
#' @param dimension Integer: 1 for rows, 2 for columns
#' @return Vector of indices with NA values
na_count <- function(data, dimension = 2) {
  if (dimension == 1) {
    return(rowSums(is.na(data)))
  } else {
    return(colSums(is.na(data)))
  }
}

#' Filter columns or rows with too many NA values
#' 
#' @param data A dataframe
#' @param na_threshold Maximum number of NA values allowed
#' @param dimension Integer: 1 for rows, 2 for columns
#' @return Filtered dataframe
filter_na <- function(data, na_threshold = 10, dimension = 2) {
  na_counts <- na_count(data, dimension)
  keep_indices <- which(na_counts < na_threshold)
  
  if (dimension == 1) {
    return(data[keep_indices, ])
  } else {
    return(data[, keep_indices])
  }
}

#' Read and preprocess CSV data
#'
#' @param file_path Path to CSV file
#' @param na_strings Vector of strings to be treated as NA
#' @return Dataframe with data from CSV
read_data_csv <- function(file_path, na_strings = c("NA", "")) {
  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }
  
  data <- read.csv(file_path, stringsAsFactors = FALSE, na.strings = na_strings)
  return(data)
}

#' Find files matching a pattern in a directory
#'
#' @param dir_path Directory path
#' @param pattern Pattern to match
#' @param full_names Whether to return full paths
#' @return Vector of file names or paths
find_files <- function(dir_path, pattern = NULL, full_names = TRUE) {
  if (!dir.exists(dir_path)) {
    stop(paste("Directory not found:", dir_path))
  }
  
  files <- list.files(dir_path, pattern = pattern, full.names = full_names)
  return(files)
}

#' Filter data by altitude
#'
#' @param data Dataframe with altitude column
#' @param alt_col Name of altitude column
#' @param max_alt Maximum altitude to include
#' @return Filtered dataframe
filter_by_altitude <- function(data, alt_col = "Hoehe", max_alt = 1500) {
  if (!(alt_col %in% colnames(data))) {
    stop(paste("Column not found:", alt_col))
  }
  
  return(data[data[[alt_col]] < max_alt, ])
}

#####################################
# Visualization Module
#####################################

#' Create a density plot for multiple datasets
#'
#' @param data_list Named list of vectors to plot
#' @param title Plot title
#' @param x_label X-axis label
#' @param y_label Y-axis label
#' @param colors Vector of colors for each dataset
#' @return ggplot object
plot_density_comparison <- function(data_list, title = "Density Comparison", 
                                   x_label = "Value", y_label = "Density",
                                   colors = NULL) {
  require(tidyverse)
  
  # Convert list to dataframe for ggplot
  df_list <- lapply(names(data_list), function(name) {
    data.frame(
      value = data_list[[name]],
      dataset = name
    )
  })
  
  df <- do.call(rbind, df_list)
  
  # Create plot
  p <- ggplot(df, aes(x = value, fill = dataset)) +
    geom_density(alpha = 0.5) +
    labs(title = title, x = x_label, y = y_label) +
    theme_minimal()
  
  if (!is.null(colors) && length(colors) >= length(data_list)) {
    p <- p + scale_fill_manual(values = colors)
  }
  
  return(p)
}

#' Create a boxplot comparison for multiple datasets
#'
#' @param data_list Named list of vectors to plot
#' @param group_var Optional grouping variable
#' @param title Plot title
#' @param x_label X-axis label
#' @param y_label Y-axis label
#' @param colors Vector of colors
#' @return ggplot object
plot_boxplot_comparison <- function(data_list, group_var = NULL, title = "Boxplot Comparison",
                                   x_label = "Dataset", y_label = "Value",
                                   colors = NULL) {
  require(tidyverse)
  
  # Convert list to dataframe for ggplot
  df_list <- lapply(names(data_list), function(name) {
    data.frame(
      value = data_list[[name]],
      dataset = name,
      group = if (is.null(group_var)) rep("A", length(data_list[[name]])) else group_var
    )
  })
  
  df <- do.call(rbind, df_list)
  
  # Create plot
  p <- ggplot(df, aes(x = dataset, y = value, fill = dataset)) +
    geom_boxplot() +
    labs(title = title, x = x_label, y = y_label) +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  if (!is.null(colors) && length(colors) >= length(data_list)) {
    p <- p + scale_fill_manual(values = colors)
  }
  
  if (!is.null(group_var)) {
    p <- ggplot(df, aes(x = dataset, y = value, fill = group)) +
      geom_boxplot() +
      labs(title = title, x = x_label, y = y_label) +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }
  
  return(p)
}

#' Create a bar plot for exceedances
#'
#' @param data_list Named list of vectors with exceedance counts
#' @param categories X-axis categories (e.g., seasons)
#' @param title Plot title
#' @param x_label X-axis label
#' @param y_label Y-axis label
#' @param colors Vector of colors
#' @return ggplot object
plot_exceedance_bars <- function(data_list, categories, title = "Exceedance Comparison",
                               x_label = "Period", y_label = "Exceedances",
                               colors = NULL) {
  require(tidyverse)
  
  # Convert data to long format
  df_list <- lapply(names(data_list), function(name) {
    data.frame(
      scenario = name,
      period = categories,
      exceedances = data_list[[name]]
    )
  })
  
  df <- do.call(rbind, df_list)
  
  # Create plot
  p <- ggplot(df, aes(x = period, y = exceedances, fill = scenario)) +
    geom_bar(stat = "identity", position = "dodge") +
    labs(title = title, x = x_label, y = y_label) +
    theme_minimal()
  
  if (!is.null(colors) && length(colors) >= length(data_list)) {
    p <- p + scale_fill_manual(values = colors)
  }
  
  return(p)
}

#####################################
# Spatial Analysis Module
#####################################

#' Map raster data to shapefile polygons
#'
#' @param raster_path Path to raster file
#' @param shapefile_path Path to shapefile
#' @param fun Function to apply (default: mean)
#' @param crs Coordinate reference system for transformation
#' @return Dataframe with mapped values
map_raster_to_polygons <- function(raster_path, shapefile_path, fun = mean, crs = 4326) {
  require(velox)
  require(sf)
  
  # Load data
  rast <- velox(raster_path)
  shp <- st_read(shapefile_path, quiet = TRUE)
  
  # Transform coordinate system if needed
  if (st_crs(shp)$epsg != crs) {
    shp <- st_transform(shp, crs)
  }
  
  # Extract values using velox
  values <- rast$extract(shp, fun = function(x) fun(x, na.rm = TRUE), small = TRUE)
  
  return(values)
}

#' Extract point values from raster
#'
#' @param raster_path Path to raster file
#' @param points Dataframe with coordinates
#' @param x_col Column name with x-coordinates
#' @param y_col Column name with y-coordinates
#' @param crs Coordinate reference system
#' @return Original dataframe with extracted values
extract_points_from_raster <- function(raster_path, points, x_col = "lon", y_col = "lat", crs = 4326) {
  require(raster)
  require(sf)
  
  # Load raster
  rast <- raster(raster_path)
  
  # Convert points to sf object
  points_sf <- st_as_sf(points, coords = c(x_col, y_col), crs = crs)
  
  # Extract values
  values <- extract(rast, points_sf)
  
  # Add values to original dataframe
  points$raster_value <- values
  
  return(points)
}

#' Simplify shapefile for faster processing
#'
#' @param shapefile_path Path to shapefile
#' @param tolerance Tolerance for simplification
#' @param output_path Path to save simplified shapefile
#' @return Path to simplified shapefile
simplify_shapefile <- function(shapefile_path, tolerance = 0.001, output_path = NULL) {
  require(sf)
  
  # Load shapefile
  shp <- st_read(shapefile_path, quiet = TRUE)
  
  # Simplify
  shp_simple <- st_simplify(shp, dTolerance = tolerance)
  
  # Save if output path provided
  if (!is.null(output_path)) {
    st_write(shp_simple, output_path, quiet = TRUE)
    return(output_path)
  }
  
  return(shp_simple)
}

#####################################
# Statistical Analysis Module
#####################################

#' Calculate exceedances based on threshold
#'
#' @param data Numeric vector or matrix
#' @param threshold Exceedance threshold
#' @return Binary values (0/1) for exceedances
calc_exceedances <- function(data, threshold = 120) {
  return(ifelse(data < threshold, 0, 1))
}

#' Calculate statistical metrics between two datasets
#'
#' @param obs Observations vector
#' @param model Model output vector
#' @return List with various statistical metrics
calc_stats_metrics <- function(obs, model) {
  # Remove NA values
  valid <- complete.cases(obs, model)
  obs_clean <- obs[valid]
  model_clean <- model[valid]
  
  # Calculate metrics
  bias <- mean(model_clean - obs_clean)
  rmse <- sqrt(mean((model_clean - obs_clean)^2))
  mae <- mean(abs(model_clean - obs_clean))
  corr <- cor(obs_clean, model_clean)
  
  return(list(
    bias = bias,
    rmse = rmse,
    mae = mae,
    correlation = corr,
    n = length(obs_clean)
  ))
}

#' Aggregate data by season
#'
#' @param data Dataframe with date column
#' @param date_col Name of date column
#' @param value_cols Vector of value column names
#' @return List of seasonal dataframes
aggregate_by_season <- function(data, date_col = "date", value_cols = NULL) {
  require(lubridate)
  
  if (is.null(value_cols)) {
    value_cols <- setdiff(colnames(data), date_col)
  }
  
  # Extract month from dates
  data$month <- month(data[[date_col]])
  
  # Define seasons
  season_map <- list(
    DJF = c(12, 1, 2),
    MAM = c(3, 4, 5),
    JJA = c(6, 7, 8),
    SON = c(9, 10, 11)
  )
  
  # Create season column
  data$season <- "Unknown"
  for (s in names(season_map)) {
    data$season[data$month %in% season_map[[s]]] <- s
  }
  
  # Aggregate by season
  result <- list()
  for (s in names(season_map)) {
    season_data <- data[data$season == s, c(date_col, value_cols)]
    result[[s]] <- season_data
  }
  
  return(result)
}

#' Wrapper function to apply statistical metrics to multiple datasets
#'
#' @param ref_data Reference dataset
#' @param model_list List of model datasets to compare
#' @return Dataframe with statistical metrics for each model
compare_models <- function(ref_data, model_list) {
  metrics <- lapply(names(model_list), function(model_name) {
    stats <- calc_stats_metrics(ref_data, model_list[[model_name]])
    data.frame(
      model = model_name,
      bias = stats$bias,
      rmse = stats$rmse,
      mae = stats$mae,
      correlation = stats$correlation,
      n_points = stats$n
    )
  })
  
  return(do.call(rbind, metrics))
}