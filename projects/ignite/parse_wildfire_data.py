#!/usr/bin/env python3
"""
Parse and clean wildfire data
"""

import pandas as pd
import numpy as np
import re
from pathlib import Path

def parse_wildfire_data(csv_path):
    """Parse wildfire data with error handling for inconsistent formats."""
    
    print("Parsing wildfire data with robust error handling...")
    
    # First, read the raw text to understand the structure
    with open(csv_path, 'r') as f:
        lines = f.readlines()
    
    print(f"Total lines in file: {len(lines)}")
    
    # Analyze line lengths to understand the structure
    line_lengths = [len(line.split(',')) for line in lines]
    print(f"Column counts: min={min(line_lengths)}, max={max(line_lengths)}, mode={max(set(line_lengths), key=line_lengths.count)}")
    
    # Expected columns based on the first few good lines
    expected_columns = [
        'fire_id', 'date', 'time', 'region', 'lon', 'lat', 'elevation',
        'cause', 'dist_to_road', 'dist_to_water', 'dist_to_settlement', 'landuse', 
        'slope', 'aspect', 'twi', 'tri', 'forest_type1', 'forest_type2', 'vegetation'
    ]
    
    parsed_records = []
    error_lines = []
    
    for i, line in enumerate(lines):
        try:
            fields = line.strip().split(',')
            
            # Skip lines that are obviously too short or too long
            if len(fields) < 19 or len(fields) > 25:
                # Try to extract multiple records from concatenated lines
                if len(fields) > 25:
                    # Look for date patterns to split concatenated records
                    date_pattern = r'\d{4}\d{6}'  # YYYYMMDD format
                    line_text = line.strip()
                    
                    # Find all positions where date patterns occur
                    matches = list(re.finditer(date_pattern, line_text))
                    
                    if len(matches) > 1:
                        # Split into multiple records
                        for j in range(len(matches)):
                            if j < len(matches) - 1:
                                start_pos = matches[j].start()
                                end_pos = matches[j+1].start()
                                record_text = line_text[start_pos:end_pos].rstrip(',')
                            else:
                                start_pos = matches[j].start()
                                record_text = line_text[start_pos:]
                            
                            record_fields = record_text.split(',')
                            if len(record_fields) >= 19:
                                parsed_records.append(record_fields[:19])
                        continue
                
                error_lines.append((i+1, len(fields), line.strip()))
                continue
            
            # Take first 19 fields if we have extra
            record = fields[:19]
            parsed_records.append(record)
            
        except Exception as e:
            error_lines.append((i+1, 0, f"Parse error: {e}"))
    
    print(f"Successfully parsed {len(parsed_records)} records")
    print(f"Error lines: {len(error_lines)}")
    
    if error_lines[:5]:  # Show first 5 errors
        print("Sample errors:")
        for line_num, field_count, error in error_lines[:5]:
            print(f"  Line {line_num}: {field_count} fields - {error[:100]}...")
    
    # Create DataFrame
    df = pd.DataFrame(parsed_records, columns=expected_columns)
    
    # Clean and convert data types
    df['lon'] = pd.to_numeric(df['lon'], errors='coerce')
    df['lat'] = pd.to_numeric(df['lat'], errors='coerce')
    df['elevation'] = pd.to_numeric(df['elevation'], errors='coerce')
    
    # Parse dates
    df['datetime'] = pd.to_datetime(df['date'], format='%m/%d/%Y', errors='coerce')
    df['year'] = df['datetime'].dt.year
    df['month'] = df['datetime'].dt.month
    df['day_of_year'] = df['datetime'].dt.dayofyear
    
    # Remove rows with invalid coordinates or dates
    valid_mask = (
        df['lon'].notna() & 
        df['lat'].notna() & 
        df['datetime'].notna() &
        (df['lon'].between(9, 18)) &  # Austria longitude range
        (df['lat'].between(46, 49))   # Austria latitude range
    )
    
    df_clean = df[valid_mask].copy()
    
    print(f"After cleaning: {len(df_clean)} valid records")
    print(f"Date range: {df_clean['datetime'].min()} to {df_clean['datetime'].max()}")
    print(f"Regions: {sorted(df_clean['region'].unique())}")
    print(f"Causes: {sorted(df_clean['cause'].unique())}")
    
    return df_clean, error_lines

def main():
    base_dir = Path("/home/cschmidt/git/GOLEM/projects/ignite")
    csv_path = base_dir / "wildfire_data.csv"
    
    if not csv_path.exists():
        print("Error: wildfire_data.csv not found!")
        return
    
    # Parse the data
    wildfire_df, errors = parse_wildfire_data(csv_path)
    
    # Save cleaned data
    output_path = base_dir / "wildfire_data_cleaned.csv"
    wildfire_df.to_csv(output_path, index=False)
    print(f"Cleaned data saved to: {output_path}")
    
    # Generate summary report
    summary = []
    summary.append("WILDFIRE DATA SUMMARY")
    summary.append("=" * 40)
    summary.append(f"Total valid records: {len(wildfire_df)}")
    summary.append(f"Date range: {wildfire_df['datetime'].min().strftime('%Y-%m-%d')} to {wildfire_df['datetime'].max().strftime('%Y-%m-%d')}")
    summary.append("")
    
    summary.append("REGIONAL DISTRIBUTION:")
    for region, count in wildfire_df['region'].value_counts().items():
        pct = count / len(wildfire_df) * 100
        summary.append(f"• {region}: {count} fires ({pct:.1f}%)")
    summary.append("")
    
    summary.append("CAUSES:")
    for cause, count in wildfire_df['cause'].value_counts().items():
        pct = count / len(wildfire_df) * 100
        summary.append(f"• {cause}: {count} fires ({pct:.1f}%)")
    summary.append("")
    
    summary.append("TEMPORAL PATTERNS:")
    monthly_counts = wildfire_df['month'].value_counts().sort_index()
    month_names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
    for month, count in monthly_counts.items():
        pct = count / len(wildfire_df) * 100
        summary.append(f"• {month_names[month-1]}: {count} fires ({pct:.1f}%)")
    summary.append("")
    
    summary.append("ELEVATION STATISTICS:")
    summary.append(f"• Mean elevation: {wildfire_df['elevation'].mean():.0f}m")
    summary.append(f"• Elevation range: {wildfire_df['elevation'].min():.0f}m - {wildfire_df['elevation'].max():.0f}m")
    summary.append(f"• Standard deviation: {wildfire_df['elevation'].std():.0f}m")
    
    # Save summary
    summary_path = base_dir / "wildfire_summary.txt"
    with open(summary_path, 'w') as f:
        f.write('\n'.join(summary))
    
    print(f"Summary saved to: {summary_path}")
    
    # Basic statistics
    print("\nQuick Statistics:")
    print(f"Coordinate ranges: Lon {wildfire_df['lon'].min():.2f} to {wildfire_df['lon'].max():.2f}")
    print(f"                   Lat {wildfire_df['lat'].min():.2f} to {wildfire_df['lat'].max():.2f}")
    print(f"Elevation range: {wildfire_df['elevation'].min():.0f}m to {wildfire_df['elevation'].max():.0f}m")

if __name__ == "__main__":
    main()