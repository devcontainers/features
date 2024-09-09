#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# 'lts' is now some version of node 20...
check "version_on_path"  node -v | grep 20
check "pnpm" bash -c "pnpm -v | grep 6.16.0"

check "v20_installed" ls -1 /usr/local/share/nvm/versions/node | grep 20
check "v14_installed" ls -1 /usr/local/share/nvm/versions/node | grep 14.19.3
check "v17_installed" ls -1 /usr/local/share/nvm/versions/node | grep 17.9.1


# Report result
reportResults
