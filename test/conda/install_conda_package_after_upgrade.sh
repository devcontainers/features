#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Test that conda can install packages without pluggy incompatibility errors
# This validates the fix for the pluggy/conda version mismatch issue where
# conda self-upgrades but the older pluggy lacks the 'wrapper' attribute
check "conda version" conda --version
check "conda update" conda update -n base -c defaults -y conda
check "conda updated version" conda --version
check "install pyopenssl" conda install -y -c defaults pyopenssl
check "install cryptography" conda install -y -c defaults cryptography
check "install scipy with bioconda" conda install -y -c bioconda scipy
check "conda-forge" conda config --show channels | grep conda-forge
check "if conda-notice.txt exists" cat /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Report result
reportResults