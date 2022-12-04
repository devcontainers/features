#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "distro" test "${VERSION_CODENAME}" = "jammy"

# Report result
reportResults