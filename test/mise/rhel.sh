#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib
# Print out where mise actually lives
echo "DEBUG: mise resolved to: $(which mise)"

# Definition specific tests
check "mise version" mise --version

# Check for correct RHEL paths
check "mise in PATH" bash -c "command -v mise | grep '/usr/local/bin/mise'"

# Report result
reportResults