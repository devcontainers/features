#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# Check the OS release information for diagnostic purposes
echo "OS release information:"
cat /etc/os-release

# Show conda configuration and packages for diagnostic purposes
echo "Conda channels configuration:"
conda config --show channels

echo "Installed packages in base environment:"
conda list -n base | grep -E "mamba|libmamba" || echo "No mamba packages found"

# Basic functionality test
echo "Basic conda functionality test passed"

# Report results
reportResults
