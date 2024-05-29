#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

check "version" az  --version

# Bicep-specific tests
check "bicep" bicep --version
check "az bicep" az bicep version

# Extract VERSION
version=$(grep '^VERSION=' /etc/os-release | awk -F'=' '{ print $2 }' | tr -d '"')

# Extract VERSION_CODENAME
version_codename=$(grep '^VERSION_CODENAME=' /etc/os-release | awk -F'=' '{ print $2 }' | tr -d '"')

# Print the results
check "version of Ubuntu" echo $version
check "version codename of Ubuntu" echo $version_codename

# Report result
reportResults