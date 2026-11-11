#!/bin/bash

set -e

source dev-container-features-test-lib

YARN_VERSION="4.3.0"

check "corepack is available" corepack --version
check "yarn shim location" bash -c ". /usr/local/share/nvm/nvm.sh && type yarn &> /dev/null"
check "download yarn" bash -c ". /usr/local/share/nvm/nvm.sh && corepack use yarn@${YARN_VERSION}"
check "yarn version" bash -c ". /usr/local/share/nvm/nvm.sh && test \"\$(yarn --version)\" = '${YARN_VERSION}'"

reportResults