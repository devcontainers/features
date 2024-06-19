#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
YARN_VERSION="4.3.0"

check "download yarn" bash -c ". /usr/local/share/nvm/nvm.sh && nvm use lts && corepack use yarn@${YARN_VERSION}"
check "yarn version" bash -c ". /usr/local/share/nvm/nvm.sh && nvm use lts && yarn --version | grep ${YARN_VERSION}"

# Report result
reportResults
