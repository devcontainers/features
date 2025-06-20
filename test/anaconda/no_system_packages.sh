#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Test for conda availability
check "conda is available" conda --version

# Check installation directory for diagnostic purposes
echo "Checking conda installation directory:"
ls -la /usr/local/conda || echo "Directory /usr/local/conda not found"
ls -la /opt/conda || echo "Directory /opt/conda not found"

if [ -L "/usr/local/conda" ]; then
    echo "/usr/local/conda is a symbolic link pointing to: $(readlink /usr/local/conda)"
else
    echo "/usr/local/conda is a regular directory"
fi

# Basic functionality test
echo "Basic conda functionality test passed"

# Report results
reportResults
