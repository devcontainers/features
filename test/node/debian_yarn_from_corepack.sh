#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
YARN_VERSION="4.3.0"

# Corepack provides shims for package managers like yarn. The first time yarn is invoked via the "yarn"
# command, corepack will interactively request permission to download the yarn binary. To
# avoid this interactive mode and download the binary automatically, we explicitly call "corepack use yarn"
# instead (doesn't require user input). Once that command completes, "yarn" can be used in a non-interactive mode.
check "yarn shim location" bash -c ". /usr/local/share/nvm/nvm.sh && type yarn &> /dev/null"
check "download yarn" bash -c ". /usr/local/share/nvm/nvm.sh && corepack use yarn@${YARN_VERSION}"
check "yarn version" bash -c ". /usr/local/share/nvm/nvm.sh && yarn --version | grep ${YARN_VERSION}"

# Report result
reportResults
