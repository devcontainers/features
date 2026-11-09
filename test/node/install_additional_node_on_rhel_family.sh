#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version_on_path" bash -c 'active_version=$(node -v) && . /usr/local/share/nvm/nvm.sh && test "${active_version}" = "$(nvm version "lts/*")"'
check "pnpm" bash -c "pnpm -v | grep 6.16.0"

check "v19_installed" bash -c "ls -1 /usr/local/share/nvm/versions/node | grep 19.9.0"
check "v20_installed" bash -c "ls -1 /usr/local/share/nvm/versions/node | grep 20.19.1"


# Report result
reportResults

