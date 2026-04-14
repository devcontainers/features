#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

## Test Conda
check "conda-update-conda" bash -c "conda update -c defaults -y conda"
check "conda-install-tensorflow" bash -c "conda create --name tensorflow-test-env -c conda-forge --yes tensorflow"
check "conda-install-pytorch" bash -c "conda create --name pytorch-test-env -c conda-forge --yes pytorch"

# Report result
reportResults
