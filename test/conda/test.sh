#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" conda --version
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Check env
check "CONDA_SCRIPT is set correctly" echo $CONDA_SCRIPT | grep "/opt/conda/etc/profile.d/conda.sh"

# Report result
reportResults
