#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "distro" test "${VERSION_CODENAME}" = "resolute"
check "bubblewrap" bwrap --version
check "socat" socat -V

# Check if the sudoers file for the non-root user exists
check "sudoers file exists" test -f /etc/sudoers.d/$(whoami)

# Check if the sudoers entry for the non-root user is correctly configured
check "sudoers entry for non-root user" sudo grep "$(whoami) ALL=(root) NOPASSWD:ALL" /etc/sudoers.d/$(whoami)

# Report result
reportResults