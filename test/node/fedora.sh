#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "libatomic runtime is installed" rpm -q libatomic
check "version" node  --version
check "npm" npm --version
check "pnpm" pnpm -v
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm install 10"
check "yarn" yarn --version

# Report result
reportResults
