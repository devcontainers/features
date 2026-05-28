#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Ubuntu plucky (25.04) is NOT in the apt archive codename allowlist,
# so this test validates the pip fallback path.
check "version" az  --version

# Report result
reportResults
