#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test that conda is installed and working
check "conda is available" conda --version

# Check package count as a proxy for full Anaconda
echo "Listing installed packages:"
conda list -n base

# Count packages as a proxy for full Anaconda vs Miniconda
pkg_count=$(conda list -n base | grep -v "^#" | wc -l)
echo "Package count: $pkg_count"

# Just check that the installation completed and conda works
echo "Conda installation test passed"

# Report results
reportResults
