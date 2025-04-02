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

# Report results
reportResults
