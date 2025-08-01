#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Load Linux distribution info
. /etc/os-release

# Check if the current user is root
check "root user" test "$(whoami)" = "root"

# Check if the Linux distro is Azure Linux
check "azurelinux distro" test "$ID" = "azurelinux"

# Definition specific tests
check "curl" curl --version
check "jq" jq  --version

# Report result
reportResults
