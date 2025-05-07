#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "mise version" mise --version

# Print out where mise actually lives
echo "DEBUG: mise resolved to: $(command -v mise)"

# Check for correct Fedora paths
check "mise in PATH" bash -c "command -v mise | grep '/usr/local/bin/mise'"

# Report result
reportResults