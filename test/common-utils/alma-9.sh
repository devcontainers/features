#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "distro" test "${PLATFORM_ID}" = "platform:el9"
check "curl" curl --version
check "jq" jq  --version

# Report result
reportResults