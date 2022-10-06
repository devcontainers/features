#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "jq" jq  --version
check "curl" curl  --version
check "DEV_CONTAINERS_DIR is set correctly" echo $DEV_CONTAINERS_DIR | grep "/usr/local/etc/vscode-dev-containers"

# Report result
reportResults