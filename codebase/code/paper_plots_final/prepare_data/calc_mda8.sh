#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_directory> <output_directory>"
    exit 1
fi


# Input and output directories
input_dir="$1"
output_dir="$2"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Process all .nc files in the input directory
for input_file in "$input_dir"/*.nc; do
    # Extract filename without path and extension
    filename=$(basename "$input_file" .nc)
    
    # Define output file
    output_file="$output_dir/${filename}_mda8.nc"
    
    echo "Processing $filename..."
    
    # Perform MDA8 calculation with piped CDO commands
    cdo -f nc4 \
        -daymax \
        -runmean,8 \
        $input_file \
        $output_file

    echo "MDA8 calculation complete for $filename. Output saved to $output_file"
done

echo "All files processed."