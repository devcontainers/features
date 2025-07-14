#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# First, ensure conda is in the PATH
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

# Try running mamba command
echo "Testing mamba command..."
if command -v mamba >/dev/null 2>&1; then
    mamba --version
    check "mamba command works" true
else
    echo "Error: mamba command not found but should be available"
    check "mamba command works" false
fi

# Report results
reportResults
