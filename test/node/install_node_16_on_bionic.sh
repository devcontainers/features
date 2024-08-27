#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" bash -c "node --version | grep 16"
check "pnpm" bash -c "pnpm -v | grep 8.8.0"
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm install 10"

# Report result
reportResults
