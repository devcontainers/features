#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Always run these checks as the non-root user
user="$(whoami)"
check "user" grep vscode <<< "$user"

# Check that the sudoers file for the non-root user does not exist
check "sudoers file does not exist" test ! -f /etc/sudoers.d/$user

# Report result
reportResults
