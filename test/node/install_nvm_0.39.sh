#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" bash -c "node --version"
check "pnpm" pnpm -v
check "nvm version" bash -c ". /usr/local/share/nvm/nvm.sh && nvm --version | grep 0.39"

# Report result
reportResults
