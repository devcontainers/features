#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "conda" bash -c "conda --version | grep 4.12.0"
check "conda-forge" bash -c "conda config --show channels | grep conda-forge"
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Report result
reportResults
