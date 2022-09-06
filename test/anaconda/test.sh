#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" conda --version
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Report result
reportResults