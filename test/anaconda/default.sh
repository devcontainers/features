#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# First, ensure conda is in the PATH
export PATH="/opt/conda/bin:$PATH"
export PATH="/usr/local/conda/bin:$PATH"

# Basic conda installation test
check "conda version" conda --version
check "notice file exists" test -f /usr/local/etc/vscode-dev-containers/conda-notice.txt
check "conda-forge channel" conda config --show channels | grep conda-forge
check "mamba installed" conda list -n base | grep mamba

# Test write access to the Conda environment
check "conda-update-conda" bash -c "conda update -y conda"
check "conda-install-tensorflow" bash -c "conda create --name test-env -c conda-forge --yes tensorflow"
check "conda-install-pytorch" bash -c "conda create --name test-env2 -c conda-forge --yes pytorch"

# Report results
reportResults
