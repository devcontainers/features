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

# Show channel priority for diagnostic purposes
echo "Channel priority configuration:"
conda config --show channel_priority

# Basic functionality test
echo "Basic conda functionality test passed"

# Report results
reportResults
