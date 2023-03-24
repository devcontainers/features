#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" node  --version
check "pnpm" pnpm -v
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm install 10"

# Report result
reportResults