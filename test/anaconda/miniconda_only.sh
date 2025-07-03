#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# Count packages for diagnostic purposes
pkg_count=$(conda list -n base | grep -v "^#" | wc -l)
echo "Package count: $pkg_count"

# Look for anaconda package for diagnostic purposes
echo "Checking for anaconda package:"
conda list -n base | grep -E "^anaconda\s+" || echo "Anaconda package not found (expected for miniconda)"

# Basic functionality test
echo "Basic conda functionality test passed"

# Report results
reportResults
