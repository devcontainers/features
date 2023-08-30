#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Ensure extended version is installed
check "extended_installed"  bash -c "hugo version | grep extended"

# Report result
reportResults
