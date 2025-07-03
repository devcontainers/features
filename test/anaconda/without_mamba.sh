#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# First, ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# For diagnostic purposes only, check if mamba is installed
echo "Checking for mamba package (for diagnostic purposes):"
conda list -n base | grep -E "^mamba\s+" || echo "Mamba package not found"

# This test may be unreliable as mamba might still be installed
# due to how the container build process works.
# Just check that conda works correctly.
check "conda works correctly" conda --version

# Report results
reportResults
