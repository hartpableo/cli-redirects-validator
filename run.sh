#!/usr/bin/env bash

# Scan a provided CSV local file containing redirect URL pairs (old and new URLs).
# Headers default to "url" and "new url".
# Perform a curl request to the old URL,
# And validate if the specified new URL matches the actual final URL in the curl response.
# Output a list of URL pairs with output status ("Matched" / "Not Matched").
# @todo: Support headers as options
# @todo: Display output in a table

