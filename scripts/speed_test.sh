#!/bin/bash

# Configuration
INPUT_FILENAME="proxies.txt"
OUTPUT_FILENAME="tested_proxies_sorted.txt"
TEST_URL="https://www.google.com"              # URL to test proxy connectivity and speed
TIMEOUT_SECONDS=5                              # Timeout for each curl request
COMMON_PORTS=(80 8080 3128 5678 8888 8000 443) # Common ports to try if only IP is given

# --- Functions ---

# Function to test a single proxy
# Arguments: proxy_address (e.g., "192.168.1.1:8080")
test_single_proxy() {
  local proxy_to_test="$1"
  local proxy_type="http" # Default to http proxy type for curl

  # curl command to test proxy speed.
  # -x: use proxy
  # -s: silent mode (don't show progress or error messages)
  # -o /dev/null: discard response body
  # -w '%{time_total}\n': output total time in seconds after the request completes
  # --connect-timeout: maximum time allowed for connection to the proxy/host
  # --max-time: maximum time allowed for the entire operation

  # Note: If you have SOCKS proxies, you might need to change -x http:// to -x socks5h://
  # This script assumes standard HTTP/HTTPS forwarding proxies.

  # Run curl and capture the total time.
  # We use 'bash -c' to ensure proper command execution and variable expansion within the pipe.
  response_time_sec=$(curl -x "${proxy_type}://${proxy_to_test}" \
    -s -o /dev/null -w '%{time_total}\n' \
    --connect-timeout "$TIMEOUT_SECONDS" \
    --max-time "$TIMEOUT_SECONDS" \
    "$TEST_URL" 2>/dev/null) # Redirect curl's stderr to /dev/null

  # Check if curl returned a valid time (a number)
  if [[ "$response_time_sec" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    # Convert seconds to milliseconds for easier comparison and readability
    response_time_ms=$(awk "BEGIN {print $response_time_sec * 1000}")
    # Print verbose success message to stderr (so it goes to console, not TEMP_RESULTS_FILE)
    echo "SUCCESS: ${proxy_to_test} - Response Time: ${response_time_ms%.*} ms" >&2
    # This is the line for sorting (to stdout), still includes time for sorting purposes
    echo "${proxy_to_test} ${response_time_ms}"
    return 0 # Success
  else
    # Print verbose failure message to stderr (so it goes to console, not TEMP_RESULTS_FILE)
    echo "FAIL: ${proxy_to_test} - (No response or connection error)" >&2
    return 1 # Failure
  fi
}

# --- Main Script Logic ---

echo "Starting proxy speed test..."
echo "Input file: ${INPUT_FILENAME}"
echo "Output file: ${OUTPUT_FILENAME}"
echo "Test URL: ${TEST_URL}"
echo "Timeout: ${TIMEOUT_SECONDS} seconds per proxy/port attempt"
echo "--------------------------------------------------"

# Check if the input file exists
if [ ! -f "$INPUT_FILENAME" ]; then
  echo "Error: Input file '${INPUT_FILENAME}' not found."
  echo "Please create '${INPUT_FILENAME}' with one proxy (IP or IP:Port) per line."
  echo ""
  echo "Example content for proxies.txt:"
  echo "---------------------------------"
  echo "139.59.88.145"
  echo "103.70.159.142:5678"
  echo "---------------------------------"
  exit 1
fi

# Create a temporary file to store results before sorting
TEMP_RESULTS_FILE=$(mktemp)

# Read proxies line by line from the input file
while IFS= read -r proxy_entry || [[ -n "$proxy_entry" ]]; do
  proxy_entry=$(echo "$proxy_entry" | xargs) # Trim whitespace

  if [ -z "$proxy_entry" ]; then
    continue # Skip empty lines
  fi

  echo "Attempting to test: ${proxy_entry}"

  if [[ "$proxy_entry" == *":"* ]]; then
    # If proxy_entry contains a colon, assume it's "IP:Port" and test directly
    # Redirect stdout of test_single_proxy to TEMP_RESULTS_FILE. Stderr goes to console.
    test_single_proxy "$proxy_entry" >>"$TEMP_RESULTS_FILE"
  else
    # If only an IP is provided, iterate through common ports
    found_working_port=false
    for port in "${COMMON_PORTS[@]}"; do
      full_proxy_address="${proxy_entry}:${port}"
      # Check if test_single_proxy was successful (returns 0)
      # Redirect stdout of test_single_proxy to TEMP_RESULTS_FILE. Stderr goes to console.
      if test_single_proxy "$full_proxy_address" >>"$TEMP_RESULTS_FILE"; then
        found_working_port=true
        break # Stop trying ports for this IP once one works
      fi
    done
    if ! $found_working_port; then
      echo "  No working configuration found for ${proxy_entry}" >&2 # Print this to stderr as well
    fi
  fi
done <"$INPUT_FILENAME"

echo "--------------------------------------------------"
echo "Proxy testing complete. Sorting results..."

# Sort the results by the response time (second column, numeric sort)
# and format them for the output file
echo "Fastest Proxies (IP:Port):" >"$OUTPUT_FILENAME"   # Changed header
echo "---------------------------" >>"$OUTPUT_FILENAME" # Changed header

if [ -s "$TEMP_RESULTS_FILE" ]; then # Check if the temp file is not empty
  sort -nk 2 "$TEMP_RESULTS_FILE" | while read -r line; do
    proxy_address=$(echo "$line" | awk '{print $1}') # Get only the IP:Port
    # response_time_ms=$(echo "$line" | awk '{print $2}') # No longer needed for output
    echo "${proxy_address}" >>"$OUTPUT_FILENAME" # Write only IP:Port
  done
else
  echo "No working proxies found among the tested ones." >>"$OUTPUT_FILENAME"
fi

# Clean up the temporary file
rm "$TEMP_RESULTS_FILE"

echo "Results saved successfully to '${OUTPUT_FILENAME}'."
echo "Please check the '${OUTPUT_FILENAME}' file for the output."
