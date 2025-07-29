#!/bin/bash

# Configuration
INPUT_CSV_FILENAME="proxies.csv"
OUTPUT_TXT_FILENAME="proxies_from_csv.txt"

echo "Starting extraction of IP and Port from CSV..."
echo "Input CSV file: ${INPUT_CSV_FILENAME}"
echo "Output TXT file: ${OUTPUT_TXT_FILENAME}"
echo "--------------------------------------------------"

# Check if the input CSV file exists
if [ ! -f "$INPUT_CSV_FILENAME" ]; then
  echo "Error: Input CSV file '${INPUT_CSV_FILENAME}' not found."
  echo "Please ensure '${INPUT_CSV_FILENAME}' is in the same directory as this script."
  exit 1
fi

# Use awk to parse the CSV, extract IP and Port, and format them.
# -F',': Sets the field separator to a comma.
# NR==1 {next}: Skips the header line.
# {print $1 ":" $8}: Prints the 1st field (ip) and the 8th field (port) separated by a colon.
# gsub(/"/, "", $1); gsub(/"/, "", $8): Removes double quotes from the IP and Port fields.
awk -F',' 'NR==1 {next} {
    gsub(/"/, "", $1); # Remove double quotes from IP
    gsub(/"/, "", $8); # Remove double quotes from Port
    print $1 ":" $8
}' "$INPUT_CSV_FILENAME" >"$OUTPUT_TXT_FILENAME"

# Check if the extraction was successful
if [ $? -eq 0 ]; then
  echo "Successfully extracted IP and Port to '${OUTPUT_TXT_FILENAME}'."
  echo "Number of entries extracted: $(wc -l <"$OUTPUT_TXT_FILENAME")"
else
  echo "Error: Failed to extract data from '${INPUT_CSV_FILENAME}'."
fi

echo "--------------------------------------------------"
echo "Done."
