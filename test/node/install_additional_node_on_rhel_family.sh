#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# 'lts' is now some version of node 22...
check "version_on_path"  node -v | grep 22
check "pnpm" bash -c "pnpm -v | grep 6.16.0"

check "v20_installed" ls -1 /usr/local/share/nvm/versions/node | grep 20
check "v19_installed" ls -1 /usr/local/share/nvm/versions/node | grep 19.9.0
check "v20_installed" ls -1 /usr/local/share/nvm/versions/node | grep 20.19.1


# Report result
reportResults
