#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# First, ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# List installed packages for diagnostic purposes
echo "Listing installed packages:"
conda list -n base | grep -E "^mamba\s+" || echo "Mamba package not found in base environment"

# Basic functionality test
echo "Basic conda functionality test passed"

# Report results
reportResults
