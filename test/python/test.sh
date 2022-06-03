#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python --version

# check "jupyterlab" jupyter lab --version
# python -m pip show jupyterlab

# Report result
reportResults
