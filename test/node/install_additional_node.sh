#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Install jq if not already installed
if ! type jq >/dev/null 2>&1; then
    apt-get update && apt-get install -y jq
fi

#Get the latest LTS version of Node.js
LATEST_LTS_VERSION=$(curl -s https://nodejs.org/dist/index.json | jq -r '[.[] | select(.lts != false)][0].version')


# 'lts' is fetched instead of hardcoded to a specific version
check "version_on_path"  node -v | grep "$LATEST_LTS_VERSION"
check "pnpm" bash -c "pnpm -v | grep 8.8.0"

check "lts_installed" ls -1 /usr/local/share/nvm/versions/node | grep "$LATEST_LTS_VERSION"
check "v14_installed" ls -1 /usr/local/share/nvm/versions/node | grep 14.19.3
check "v17_installed" ls -1 /usr/local/share/nvm/versions/node | grep 17.9.1


# Report result
reportResults
