#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Always run these checks as the non-root user
user="$(whoami)"
check "user" grep vscode <<< "$user"

# Check for an installation of Poetry
check "version" poetry --version

# Check location of Poetry installation
packages="$(python3 -m pip list)"
check "location" grep poetry <<< "$packages"

# Report result
reportResults
