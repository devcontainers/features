#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" node  --version
check "pnpm" pnpm -v
# for some reason the "nvm" test switches the default node version on Mariner
# test yarn before that: it is only enabled in the default node version
check "yarn" yarn --version_list
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm install 10"

# Report result
reportResults