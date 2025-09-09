#!/bin/bash
for file in met_em.*.nc; do
  echo "Processing $file"
  # Dump the netcdf file to CDL
  ncdump "$file" > "${file}.cdl"

  # Get the date string from the file name
  date_str=$(echo "$file" | cut -d'.' -f3)
  new_date_str="2018-${date_str:5}"

  # Use sed to replace the date string in the CDL file
  sed -i "s/2004-12-01_00:00:00/$new_date_str/g" "${file}.cdl"

  # Generate the new netcdf file
  ncgen -o "${file}.new" "${file}.cdl"

  # Replace the old file with the new one
  mv "${file}.new" "$file"

  # Remove the temporary cdl file
  rm "${file}.cdl"
done