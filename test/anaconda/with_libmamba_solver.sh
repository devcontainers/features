#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# Specifically test for mamba installation
echo "Checking for mamba package..."
if conda list -n base | grep -E "^mamba\s+"; then
    echo "Found mamba package as expected"
    check "mamba is installed" true
else
    echo "Error: mamba package not found but should be installed"
    check "mamba is installed" false
fi

# Check solver configuration
echo "Checking solver configuration..."
if conda config --show solver | grep -q "libmamba"; then
    echo "libmamba solver is configured as expected"
    check "libmamba solver is configured" true
else
    echo "Error: libmamba solver not configured but should be"
    check "libmamba solver is configured" false
fi

# Report results
reportResults
