#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
EXPECTED_VERSION=$(~/.ghcup/bin/ghcup list | grep "ghc " | grep recommended | awk '{print $3}')
echo ${EXPECTED_VERSION}
check "version" ~/.ghcup/bin/ghc --version | grep "${EXPECTED_VERSION}"

# Report result
reportResults