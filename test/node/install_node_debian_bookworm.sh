#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
YARN_VERSION="4.9.4"

# Definition specific tests
check "version" node  --version
check "pnpm" pnpm -v
check "yarn" yarn --version

if command -v corepack > /dev/null 2>&1; then
    check "yarn shim location" bash -c ". /usr/local/share/nvm/nvm.sh && type yarn &> /dev/null"
    check "download yarn" bash -c ". /usr/local/share/nvm/nvm.sh && corepack use yarn@${YARN_VERSION}"
    check "yarn version" bash -c ". /usr/local/share/nvm/nvm.sh && test \"\$(yarn --version)\" = '${YARN_VERSION}'"
else
    check "yarn installed through npm" npm list --global yarn
    check "yarn classic version" bash -c "yarn --version | grep -E '^1\.'"
fi

check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm install 10"

# Report result
reportResults
