#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# 'lts' is now some version of node 22...
check "version_on_path" bash -c "node -v | grep 24"
check "pnpm" bash -c "pnpm -v | grep 8.8.0"

check "v20_installed" bash -c "ls -1 /usr/local/share/nvm/versions/node | grep 20.19.1"
check "v19_installed" bash -c "ls -1 /usr/local/share/nvm/versions/node | grep 19.9.0"


# Report result
reportResults