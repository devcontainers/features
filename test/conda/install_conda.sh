#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "conda" conda --version
check "conda-forge" conda config --show channels | grep conda-forge
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Report result
reportResults
