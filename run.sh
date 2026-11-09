#!/usr/bin/env bash

# Scan a provided CSV local file containing redirect URL pairs (old and new URLs).
# Headers default to "url" and "new url".
# Perform a curl request to the old URL,
# And validate if the specified new URL matches the actual final URL in the curl response.
# Output a list of URL pairs with output status ("Matched" / "Not Matched").
# @todo: Support headers as options
# @todo: Display output in a table

# Require $1 - csv file
if [[ -n $1 ]]; then
  CSV_FILE=$1
else
  echo "Provide a csv file"
  exit 1
fi

# More vars
CURRENT_URL_HEADER="url"
NEW_URL_HEADER="new url"

# Helper function to check if URL is valid
function url_is_valid() {
	local regex='^(https?://)?([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})(/[^[:space:]]*)?$'

	if [[ "$1" =~ $regex ]]; then
      return 0
  else
      return 1
  fi
}

# Read row by row
TOTAL=0
FAILED_COUNT=0
SUCCESS_COUNT=0
while IFS=',' read -r -a row; do
	# Skip headers
	if [[ "${row[0]}" == "$CURRENT_URL_HEADER" ]]; then
		continue
	fi

	((TOTAL++))

	if ! url_is_valid "${row[0]}" || ! url_is_valid "${row[1]}"; then
      echo "Skipping row: ${row[0]} -> ${row[1]}"
      ((FAILED_COUNT++))
      continue
  fi

	echo "First Column: ${row[0]}"
	echo "Second Column: ${row[1]}"
	echo "-------------------"
	((SUCCESS_COUNT++))
done < "$CSV_FILE"

echo "Success: ${SUCCESS_COUNT} / ${TOTAL}"
echo "Failed: ${FAILED_COUNT} / ${TOTAL}"
