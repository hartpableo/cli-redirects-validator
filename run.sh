#!/usr/bin/env bash

# Scan a provided CSV local file containing redirect URL pairs (old and new URLs).
# Headers default to "url" and "new url".
# Perform a curl request to the old URL,
# And validate if the specified new URL matches the actual final URL in the curl response.
# Output a list of URL pairs with output status ("Matched" / "Not Matched").
# @todo: Support csv headers as args
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
#NEW_URL_HEADER="new url"
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
CONN_TIMEOUT=5
MAX_TIME=10

# Helper function to check if URL is valid
url_is_valid() {
	local regex='^(https?://)?([a-zA-Z0-9.-]+)\.([a-zA-Z]{2,})(/[^[:space:]]*)?$'

	if [[ "$1" =~ $regex ]]; then
      return 0
  else
      return 1
  fi
}

# Read row by row
TOTAL=0
SUCCESSFUL_URLS=()
FAILED_URLS=()
NOT_FOUND_URLS=()
SKIPPED_URLS=()

# Loop
while IFS=',' read -r ORIGINAL_URL REDIRECT_URL || [[ -n "$ORIGINAL_URL" ]]; do
	ORIGINAL_URL="${ORIGINAL_URL%$'\r'}"
	ORIGINAL_URL="${ORIGINAL_URL#\"}"
	ORIGINAL_URL="${ORIGINAL_URL%\"}"

	REDIRECT_URL="${REDIRECT_URL%$'\r'}"
	REDIRECT_URL="${REDIRECT_URL#\"}"
	REDIRECT_URL="${REDIRECT_URL%\"}"

	# Skip headers
	if [[ "${ORIGINAL_URL}" == "$CURRENT_URL_HEADER" ]]; then
		continue
	fi

	((TOTAL++))

	if ! url_is_valid "${ORIGINAL_URL}" || ! url_is_valid "${REDIRECT_URL}"; then
      echo "Skipping row: ${ORIGINAL_URL} -> ${REDIRECT_URL}"
      SKIPPED_URLS+=("${ORIGINAL_URL} | ${REDIRECT_URL}")
      continue
  fi

	echo "Checking ${ORIGINAL_URL}"

	CURL_OUTPUT=$(curl -Ls -o /dev/null \
							-w "%{url_effective}|%{http_code}" \
							-A "$USER_AGENT" \
							--connect-timeout "$CONN_TIMEOUT" \
							--max-time "$MAX_TIME" \
							"${ORIGINAL_URL}")

	IFS="|" read -r FINAL_URL STATUS_CODE <<< "$CURL_OUTPUT"

	echo "Final URL: ${FINAL_URL}"

	if [[ "${FINAL_URL%/}" == "${REDIRECT_URL%/}" ]]; then
		# Ensure status code is 2**
		if [[ "$STATUS_CODE" -ge 200 && "$STATUS_CODE" -lt 300 ]]; then
			echo "Good match with expected final URL: ${REDIRECT_URL}"
			SUCCESSFUL_URLS+=("${ORIGINAL_URL} | ${FINAL_URL}")
		else
			echo "Good match but final URL is not ok: ${REDIRECT_URL}"
			NOT_FOUND_URLS+=("${ORIGINAL_URL} | ${FINAL_URL}")
		fi
	else
		echo "Not a good match: ${FINAL_URL} <> ${REDIRECT_URL}"
		FAILED_URLS+=("${ORIGINAL_URL} | ${REDIRECT_URL} | ${FINAL_URL}")
	fi

	SLEEP_TIME=$(awk "BEGIN {srand(); print 1 + rand() * 2}")
	echo "Sleeping for ${SLEEP_TIME}s to prevent spamming..."
	sleep "$SLEEP_TIME"
	echo "-------------------------------"
	echo ""
done < "$CSV_FILE"

# Output
echo "================================="
echo "Success: ${#SUCCESSFUL_URLS[@]} / ${TOTAL}"
echo "================================="
echo ""

echo "================================="
echo "Failed: ${#FAILED_URLS[@]} / ${TOTAL}"
for (( i = 0; i < ${#FAILED_URLS[@]}; i++ )); do
	echo "$i: ${FAILED_URLS[i]}"
	echo "-------------------------------"
done
echo "================================="
echo ""

echo "================================="
echo "Not OK: ${#NOT_FOUND_URLS[@]} / ${TOTAL}"
for (( i = 0; i < ${#NOT_FOUND_URLS[@]}; i++ )); do
	echo "$i: ${NOT_FOUND_URLS[i]}"
	echo "-------------------------------"
done
echo "================================="
echo ""

echo "================================="
echo "Skipped: ${#SKIPPED_URLS[@]} / ${TOTAL}"
for (( i = 0; i < ${#SKIPPED_URLS[@]}; i++ )); do
	echo "$i: ${SKIPPED_URLS[i]}"
	echo "-------------------------------"
done
echo "================================="
echo ""
