#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# First, ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Basic conda installation tests
check "conda version check" conda --version
check "conda notice file exists" test -f /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Show conda configuration and packages for diagnostic purposes
echo "Conda channels configuration:"
conda config --show channels

echo "Channel priority configuration:"
conda config --show channel_priority

echo "Installed packages in base environment:"
conda list -n base

# Test basic conda functionality
check "conda can list environments" conda env list

# Report results
reportResults
