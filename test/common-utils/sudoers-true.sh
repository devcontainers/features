#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Always run these checks as the non-root user
user="$(whoami)"
check "user" grep vscode <<< "$user"

# Check if the sudoers file for the non-root user exists
check "sudoers file exists" test -f /etc/sudoers.d/$user

# Check if the sudoers entry for the non-root user is correctly configured
check "sudoers entry for non-root user" sudo grep "$user ALL=(root) NOPASSWD:ALL" /etc/sudoers.d/$user

# Report result
reportResults
