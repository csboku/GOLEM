# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build/Run Commands
- WRF-Chem: `cd wrfchem && ./compile em_real`
- Julia: Run scripts directly with `julia script.jl` or TRURL with `julia src/main.jl`
- R: Execute scripts with `Rscript script.R`
- Python: Run with `python script.py`
- Lint Julia: `julia -e 'using JuliaFormatter; format(".")'`

## Code Style Guidelines
- Julia: Use snake_case for functions/variables, pipe operator `|>` for data transformation
- R: Follow tidyverse style with pipe operator `%>%`, snake_case naming
- Python: Use snake_case, group imports (stdlib first, then third-party)
- Fortran: Follow standard scientific computing conventions
- GTK UI: Separate view logic from computational logic

## Project Structure
- `/codebase/code/`: Core analysis and plotting scripts (Julia, R)
- `/wrfchem/`: WRF-Chem model and chemistry modules (Fortran)
- `/preproc/`, `/postproc/`: Pre/post-processing utilities
- `/sw/`: Software environment configuration
- `/trurl/`: TRURL toolkit (Julia GTK GUI for plotting)
  - `/assets/`: Static resources
  - `/config/`: Configuration files
  - `/src/`: Core application code
  - `/ui/`: GTK UI components

## Best Practices
- Preserve absolute path structure in file operations
- Maintain consistent variable naming within each language
- Follow existing error handling patterns (minimal try/catch)
- When editing visualization code, maintain the existing plotting library usage
- Document function behavior with Julia docstrings