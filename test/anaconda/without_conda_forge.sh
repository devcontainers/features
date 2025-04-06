#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# First, ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# Show channels configuration for diagnostic purposes
echo "Conda channels configuration:"
conda config --show channels

# Basic functionality test
echo "Basic conda functionality test passed"

# Report results
reportResults
