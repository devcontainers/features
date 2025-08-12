#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "group name is adm" test "$(id -gn)" = "adm"

# Report result
reportResults
