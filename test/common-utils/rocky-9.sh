#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "distro" test "${PLATFORM_ID}" = "platform:el9"

# Report result
reportResults