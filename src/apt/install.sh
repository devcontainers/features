#!/bin/bash

set -e

# Exit script if any command fails
set -o errexit

# Debugging (optional, comment out if not needed)
# set -x

# Use the DEVFILE environment variable to find the Aptfile.dev
if [ -f "$DEVFILE" ]; then
  echo "Aptfile.dev detected at $DEVFILE. Installing dependencies..."

  apt-get update -y
  grep -Ev "^\s*#" "$DEVFILE" | xargs apt-get install --no-install-recommends -y
  rm -rf /var/lib/apt/lists/*

  echo "Dependencies from $DEVFILE have been installed."
else
  echo "No Aptfile.dev found at $DEVFILE, skipping apt dependencies installation."
fi
