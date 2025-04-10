# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- Julia: Run scripts with `julia script.jl`
- R: Execute scripts with `Rscript script.R`
- Python: Run with `python script.py`
- Lint Julia: `julia -e 'using JuliaFormatter; format(".")'`
- TRURL: `julia trurl/src/main.jl` (GTK GUI toolkit)

## Code Style Guidelines
- Julia: Use snake_case for functions/variables, function_name = function(args) pattern
- R: Follow tidyverse style with snake_case naming
- Python: Use snake_case, group imports (matplotlib before custom modules)
- All: Descriptive variable names and absolute paths for file operations
- Visualization: Use Plots.jl, CairoMakie, or ggplot2 (R) based on file context

## Project Structure
- `/codebase/code/`: Analysis and plotting scripts organized by functionality
  - `plot_*`: Visualization scripts for various datasets
  - `meas_model_comp/`: Measurement-model comparison tools
  - `paper_plots_final/`: Publication-ready visualizations
- Data processing patterns used consistently across languages
- Output typically saved to `plots/` subdirectories

## Best Practices
- Preserve absolute paths in file operations
- Maintain consistent variable naming conventions
- Function definitions should include clear input/output parameters
- Plotting: Follow existing library patterns (Makie, Plots.jl)
- Data transformation: Use vectorized operations when possible