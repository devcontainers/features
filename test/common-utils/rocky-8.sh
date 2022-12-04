#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "distro" test "${REDHAT_SUPPORT_PRODUCT_VERSION}" = "8"

# Report result
reportResults