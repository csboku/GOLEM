# Pixi Package Manager - Complete Manual & Cheat Sheet

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Core Concepts](#core-concepts)
- [Getting Started](#getting-started)
- [Command Reference](#command-reference)
- [Configuration](#configuration)
- [Best Practices](#best-practices)
- [Quick Reference Cheat Sheet](#quick-reference-cheat-sheet)

---

## Introduction

**Pixi** is a cross-platform, multi-language package manager and workflow tool built on the foundation of the conda ecosystem. It provides developers with an exceptional experience similar to popular package managers like cargo or yarn, but for any language.

### Key Features:
- **Multi-language support**: Python, C++, R, Rust, Ruby, and many others
- **Cross-platform**: Works on Linux, Windows, macOS (including Apple Silicon)
- **Project-focused approach**: Unlike conda's environment focus, pixi centers around projects
- **Always up-to-date lock files**: Ensures reproducible environments
- **Fast Rust implementation**: Built entirely in Rust using the rattler library
- **Conda ecosystem compatibility**: Uses conda-forge and other conda channels

---

## Installation

### Unix/Linux/macOS
```bash
curl -fsSL https://pixi.sh/install.sh | sh
```

### Windows
```powershell
powershell -ExecutionPolicy ByPass -c "irm -useb https://pixi.sh/install.ps1 | iex"
```

### Alternative Methods

#### Homebrew (macOS/Linux)
```bash
brew install pixi
```

#### Cargo (Rust)
```bash
cargo install --locked --git https://github.com/prefix-dev/pixi.git
```

#### Windows Installer
Download MSI installer from [GitHub releases](https://github.com/prefix-dev/pixi/releases)

### Shell Completion Setup

#### Bash
```bash
echo 'eval "$(pixi completion --shell bash)"' >> ~/.bashrc
```

#### Zsh
```bash
echo 'eval "$(pixi completion --shell zsh)"' >> ~/.zshrc
```

#### Fish
```bash
echo 'pixi completion --shell fish | source' >> ~/.config/fish/config.fish
```

#### PowerShell
```powershell
pixi completion --shell powershell | Out-String | Invoke-Expression
```

---

## Core Concepts

### Projects vs Environments
- **Conda/Mamba**: Focus on environment management with global environments
- **Pixi**: Project-centric approach where each project has its own environment

### Project Structure
```
my-project/
├── pixi.toml          # Main manifest file
├── pyproject.toml     # Alternative manifest (Python projects)
├── pixi.lock          # Lock file with exact dependencies
└── .pixi/             # Environment directory
    └── envs/
        └── default/   # Default environment
```

### Key Files

#### `pixi.toml` (Manifest)
Contains project metadata, dependencies, tasks, and environment configuration.

#### `pixi.lock` (Lock File)
Automatically generated file containing exact versions of all dependencies across all platforms.

#### `.pixi/` Directory
Contains the actual environment with installed packages. Should be added to `.gitignore`.

---

## Getting Started

### 1. Initialize a New Project
```bash
# Create new project in current directory
pixi init

# Create new project in specific directory
pixi init my-project

# Initialize with specific channels
pixi init --channel conda-forge --channel bioconda my-project

# Initialize with pyproject.toml format
pixi init --format pyproject

# Import existing environment.yml
pixi init --import environment.yml
```

### 2. Add Dependencies
```bash
# Add conda packages
pixi add numpy pandas "python>=3.9"

# Add PyPI packages
pixi add --pypi requests[security]
pixi add --pypi "Django==5.1rc1"

# Add to specific platforms
pixi add --platform osx-64 clang

# Add to specific features/environments
pixi add --feature cuda pytorch
```

### 3. Install Environment
```bash
# Install the default environment
pixi install

# Install specific environment
pixi install --environment cuda
```

### 4. Run Commands
```bash
# Run commands in the environment
pixi run python script.py
pixi run pytest

# Run custom tasks (defined in pixi.toml)
pixi run build
```

---

## Command Reference

### Project Management

#### `pixi init [PATH]`
Initialize a new pixi project.

**Options:**
- `--channel <CHANNEL> (-c)`: Specify channels (default: conda-forge)
- `--platform <PLATFORM> (-p)`: Specify platforms
- `--import <ENV_FILE> (-i)`: Import conda environment file
- `--format <FORMAT>`: File format (pixi or pyproject)

**Examples:**
```bash
pixi init my-project
pixi init --channel bioconda --platform linux-64 bio-project
pixi init --import environment.yml
```

#### `pixi info`
Show system information about pixi installation.

**Options:**
- `--extended`: Include slow queries for detailed info
- `--json`: Output in JSON format

### Dependency Management

#### `pixi add [SPECS]`
Add dependencies to the project.

**Options:**
- `--pypi`: Add PyPI dependency
- `--platform <PLATFORM> (-p)`: Platform-specific dependency
- `--feature <FEATURE> (-f)`: Add to specific feature
- `--host`: Host dependency (for building)
- `--build`: Build dependency
- `--no-install`: Don't install, just update manifest
- `--editable`: Editable PyPI dependency

**Examples:**
```bash
pixi add numpy pandas "pytorch>=1.8"
pixi add --pypi requests beautifulsoup4
pixi add --platform osx-64 --feature ml tensorflow
pixi add --host "python>=3.9"
pixi add --pypi "project@file:///path/to/project" --editable
```

#### `pixi remove <DEPS>`
Remove dependencies from the project.

**Options:**
- `--pypi`: Remove PyPI dependency
- `--platform <PLATFORM> (-p)`: Remove from specific platform
- `--feature <FEATURE> (-f)`: Remove from specific feature
- `--host/--build`: Remove host/build dependency

**Examples:**
```bash
pixi remove numpy pandas
pixi remove --pypi requests
pixi remove --platform osx-64 --feature ml tensorflow
```

#### `pixi update [PACKAGES]`
Update dependencies to newer versions.

**Options:**
- `--environment <ENV> (-e)`: Update specific environment
- `--platform <PLATFORM> (-p)`: Update for specific platform
- `--dry-run (-n)`: Show changes without applying
- `--json`: Output changes in JSON

**Examples:**
```bash
pixi update                    # Update all packages
pixi update numpy pandas       # Update specific packages
pixi update --dry-run          # Preview changes
pixi update --environment cuda python
```

#### `pixi upgrade [PACKAGES]`
Upgrade dependencies by loosening version constraints.

**Options:**
- `--feature <FEATURE> (-f)`: Upgrade in specific feature
- `--dry-run (-n)`: Preview changes
- `--json`: Output in JSON format

### Environment Management

#### `pixi install`
Install the project environment.

**Options:**
- `--environment <ENV> (-e)`: Install specific environment
- `--frozen`: Install from lock file without updating
- `--locked`: Only install if lock file is up-to-date

**Examples:**
```bash
pixi install
pixi install --environment cuda
pixi install --frozen
```

#### `pixi shell`
Start a shell in the project environment.

**Options:**
- `--environment <ENV> (-e)`: Use specific environment
- `--change-ps1 <BOOL>`: Show (pixi) prefix in prompt
- `--frozen/--locked`: Environment update behavior

**Examples:**
```bash
pixi shell
pixi shell --environment cuda
pixi shell --change-ps1 false
```

#### `pixi shell-hook`
Generate activation script for the environment.

**Options:**
- `--shell <SHELL> (-s)`: Target shell (bash, zsh, fish, etc.)
- `--environment <ENV> (-e)`: Use specific environment
- `--json`: Output environment variables as JSON

**Examples:**
```bash
pixi shell-hook
pixi shell-hook --shell zsh
pixi shell-hook --json
eval "$(pixi shell-hook)"
```

### Running Commands

#### `pixi run [TASK]`
Run commands or tasks in the project environment.

**Options:**
- `--environment <ENV> (-e)`: Use specific environment
- `--clean-env`: Remove shell environment variables (Unix only)
- `--frozen/--locked`: Environment update behavior
- `--skip-deps`: Skip task dependencies

**Examples:**
```bash
pixi run python script.py
pixi run --environment cuda train-model
pixi run --clean-env "echo $PATH"
pixi run --skip-deps build
```

#### `pixi exec <COMMAND>`
Run commands in temporary environments.

**Options:**
- `--spec <SPECS> (-s)`: Package specifications to install
- `--channel <CHANNELS> (-c)`: Channels to use
- `--force-reinstall`: Always create new environment

**Examples:**
```bash
pixi exec python
pixi exec -s python=3.9 python
pixi exec -s ipython -s numpy ipython
```

### Task Management

#### `pixi task add <NAME> <COMMAND>`
Add a custom task to the project.

**Options:**
- `--platform <PLATFORM> (-p)`: Platform-specific task
- `--feature <FEATURE> (-f)`: Feature-specific task
- `--depends-on <DEPS>`: Task dependencies
- `--cwd <CWD>`: Working directory for task
- `--env <ENV>`: Environment variables

**Examples:**
```bash
pixi task add build "cargo build"
pixi task add test pytest --depends-on build
pixi task add format "black ." --cwd src
pixi task add deploy "python deploy.py" --env "ENV=prod"
```

#### `pixi task remove <NAMES>`
Remove tasks from the project.

#### `pixi task list`
List all available tasks.

**Options:**
- `--environment (-e)`: Show tasks for specific environment
- `--summary (-s)`: Show summary per environment

#### `pixi task alias <ALIAS> <TASKS>`
Create an alias for multiple tasks.

**Examples:**
```bash
pixi task alias test-all test-py test-cpp test-rust
pixi task alias ci build test lint
```

### Information Commands

#### `pixi list [REGEX]`
List project packages.

**Options:**
- `--platform <PLATFORM> (-p)`: Platform to list for
- `--environment (-e)`: Environment to list
- `--explicit (-x)`: Only explicit dependencies
- `--json/--json-pretty`: JSON output
- `--sort-by <SORT_BY>`: Sort by name, size, or type

**Examples:**
```bash
pixi list
pixi list py.*
pixi list --explicit --sort-by size
pixi list --environment cuda --json-pretty
```

#### `pixi tree [REGEX]`
Display dependency tree.

**Options:**
- `--invert (-i)`: Show reverse dependencies
- `--platform <PLATFORM> (-p)`: Platform to analyze
- `--environment (-e)`: Environment to analyze

**Examples:**
```bash
pixi tree
pixi tree numpy
pixi tree -i python  # What depends on python?
```

#### `pixi search <PACKAGE>`
Search for packages.

**Options:**
- `--channel <CHANNEL> (-c)`: Search specific channels
- `--limit <LIMIT> (-l)`: Limit results
- `--platform <PLATFORM> (-p)`: Platform-specific search

**Examples:**
```bash
pixi search numpy
pixi search --limit 10 "py*"
pixi search -c bioconda --platform linux-64 "bio*"
```

### Global Commands

#### `pixi global install <PACKAGE>`
Install packages globally.

**Options:**
- `--channel <CHANNEL> (-c)`: Specify channels
- `--platform <PLATFORM> (-p)`: Target platform
- `--environment <ENV> (-e)`: Environment name
- `--expose <EXPOSE>`: Binary name mapping
- `--with <WITH>`: Additional dependencies

**Examples:**
```bash
pixi global install ruff
pixi global install python=3.9 --environment py39
pixi global install --expose py39=python python=3.9
pixi global install jupyter --with numpy --with pandas
```

#### `pixi global list`
List globally installed packages.

#### `pixi global remove <PACKAGE>`
Remove global packages.

#### `pixi global update [ENVIRONMENT]`
Update global environments.

### Project Configuration

#### `pixi project channel add <CHANNEL>`
Add channels to the project.

**Examples:**
```bash
pixi project channel add bioconda
pixi project channel add https://repo.prefix.dev/conda-forge
```

#### `pixi project platform add <PLATFORM>`
Add platforms to the project.

#### `pixi project environment add <NAME>`
Add new environment to the project.

**Options:**
- `--feature <FEATURES> (-f)`: Include features
- `--solve-group <GROUP>`: Solve group
- `--no-default-feature`: Exclude default feature

### System Commands

#### `pixi clean`
Clean project environments and caches.

**Options:**
- `--environment <ENV> (-e)`: Clean specific environment

#### `pixi clean cache`
Clean pixi system caches.

**Options:**
- `--pypi/--conda/--mapping/--exec/--repodata`: Specific cache types
- `--yes`: Skip confirmation

#### `pixi self-update`
Update pixi to the latest version.

**Options:**
- `--version <VERSION>`: Update to specific version

---

## Configuration

### Configuration Hierarchy
1. **Local**: `.pixi/config.toml` (project-specific)
2. **Global**: `~/.pixi/config.toml` (user-specific)
3. **System**: `/etc/pixi/config.toml` (system-wide)

### Common Configuration Options

#### Default Channels
```toml
default-channels = ["conda-forge", "bioconda"]
```

#### Package Installation
```toml
[package-install]
concurrent-downloads = 50
concurrent-solves = 8
```

#### Environment Variables
```toml
[env]
RUST_LOG = "info"
```

#### Pinning Strategy
```toml
pinning-strategy = "semver"  # Options: "semver", "minor", "patch", "major", "no-pin"
```

### Configuration Commands
```bash
# Edit configuration
pixi config edit
pixi config edit --global
pixi config edit --system

# List configuration
pixi config list
pixi config list --json

# Set values
pixi config set default-channels '["conda-forge", "bioconda"]'
pixi config set --global detached-environments "/opt/pixi/envs"

# Unset values
pixi config unset default-channels
```

---

## Best Practices

### 1. Project Organization
- Keep `pixi.toml` in version control
- Add `.pixi/` to `.gitignore`
- Use meaningful task names
- Group related dependencies in features

### 2. Dependency Management
- Pin critical dependencies with specific versions
- Use version ranges for flexibility: `"python>=3.9,<3.12"`
- Prefer conda packages over PyPI when available
- Use `--pypi` only when necessary

### 3. Multi-Environment Setup
```toml
[environments]
default = {features = ["base"], solve-group = "default"}
test = {features = ["base", "test"], solve-group = "default"}
docs = {features = ["base", "docs"]}
cuda = {features = ["base", "gpu"]}
```

### 4. Task Definition
```toml
[tasks]
test = "pytest tests/"
lint = "ruff check ."
format = "ruff format ."
docs = "mkdocs serve"
build = {cmd = "python -m build", depends-on = ["test", "lint"]}
```

### 5. Platform-Specific Configuration
```toml
[target.linux-64.dependencies]
gcc = ">=9.0"

[target.osx-arm64.dependencies]
llvm = ">=12.0"

[target.win-64.dependencies]
vs2019_win-64 = "*"
```

---

## Quick Reference Cheat Sheet

### Essential Commands
```bash
# Project Setup
pixi init my-project              # Create new project
pixi add python numpy             # Add dependencies
pixi add --pypi requests          # Add PyPI package
pixi install                      # Install environment

# Daily Workflow  
pixi run python script.py         # Run command
pixi shell                        # Enter environment shell
pixi task add build "make"        # Add custom task
pixi run build                    # Run custom task

# Dependency Management
pixi list                         # List packages
pixi tree                         # Dependency tree
pixi update                       # Update packages
pixi remove numpy                 # Remove package

# Multiple Environments
pixi add --feature test pytest    # Add to test feature
pixi run --environment test pytest # Run in test env
pixi install --environment test   # Install test env

# Global Tools
pixi global install ruff          # Install global tool
pixi global list                  # List global tools
pixi exec -s python=3.9 python    # Temporary environment
```

### File Structure
```
project/
├── pixi.toml                     # Main manifest
├── pixi.lock                     # Lock file (auto-generated)
├── .pixi/                        # Environment (add to .gitignore)
│   └── envs/
│       ├── default/
│       └── test/
└── src/
```

### Manifest Example (`pixi.toml`)
```toml
[project]
name = "my-project"
version = "0.1.0"
description = "My awesome project"
channels = ["conda-forge", "bioconda"]
platforms = ["linux-64", "osx-64", "win-64"]

[dependencies]
python = ">=3.9,<3.12"
numpy = ">=1.20"

[pypi-dependencies]
requests = ">=2.25"

[feature.test.dependencies]
pytest = "*"
pytest-cov = "*"

[feature.docs.dependencies]
mkdocs = "*"

[environments]
default = {features = ["base"], solve-group = "default"}
test = {features = ["base", "test"], solve-group = "default"}
docs = {features = ["base", "docs"]}

[tasks]
test = "pytest tests/"
docs = "mkdocs serve"
build = {cmd = "python -m build", depends-on = ["test"]}
format = "ruff format ."
lint = "ruff check ."
```

### Common Flags
```bash
# Environment Selection
-e, --environment <ENV>           # Use specific environment

# Platform Selection  
-p, --platform <PLATFORM>        # Target platform

# Installation Behavior
--frozen                          # Use lock file as-is
--locked                          # Only install if lock up-to-date
--no-install                      # Don't install, just update manifest

# Output Formats
--json                           # JSON output
--dry-run, -n                    # Preview changes
-v, --verbose                    # Verbose output
```

### Troubleshooting
```bash
# Check environment status
pixi info
pixi list --environment test

# Clean and reinstall
pixi clean
pixi install --force-reinstall

# Update lock file
pixi update --no-install

# Check what changed
pixi update --dry-run --json

# Environment debugging
pixi shell-hook --json           # See environment variables
pixi run env                     # Check environment in shell
```

### Environment Variables
```bash
# Pixi Configuration
PIXI_HOME                        # Override default ~/.pixi
PIXI_CACHE_DIR                   # Cache directory
PIXI_CONFIG_FILE                 # Config file location

# Behavior Control
PIXI_FROZEN=true                 # Equivalent to --frozen
PIXI_LOCKED=true                 # Equivalent to --locked
PIXI_COLOR=always|never|auto     # Color output
PIXI_NO_PROGRESS=1               # Disable progress bars
```

---

*This manual covers pixi v0.40+. For the latest features and updates, visit [pixi.sh](https://pixi.sh) or the [GitHub repository](https://github.com/prefix-dev/pixi).*