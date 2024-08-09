#!/bin/bash

command=$1
expected=$2

echo -e "Checking completion for command '$command'..."

# Send command as a character stream, followed by two tab characters, into an interactive bash shell.
# Also note the 'y' which responds to the possible Bash question "Display all xxx possibilities? (y or n)".
# Bash produces the autocompletion output on stderr, so redirect that to stdout.
# The sed bit captures the lines between Header and Footer (used as output delimiters).
# The first grep removes the "Display all" message (that is atomatically answered to "y" by the script).
# The last grep filters the output to lines containing the expected result.
COMPLETE_OUTPUT=$(echo if false\; then "Header"\; $command$'\t'$'\t'y\; "Footer" fi | bash -i 2>&1 | sed -n '/Header/{:a;n;/Footer/q;p;ba}' | grep -v ^'Display all ')
echo -e "\nCompletion output:\n"
echo -e "$COMPLETE_OUTPUT"
echo -e "\n"

FILTERED_COMPLETE_OUTPUT=$(echo "$COMPLETE_OUTPUT" | grep "$expected")

if [ -z "$FILTERED_COMPLETE_OUTPUT" ]; then
  echo -e "Completion output does not contains '$expected'."
  exit 1
else
  echo -e "Completion output contains '$expected'."
  exit 0
fi
