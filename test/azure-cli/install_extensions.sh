#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Extension-specific tests
check "aks-preview" az extension show --name aks-preview
check "amg" az extension show --name amg
check "containerapp" az extension show --name containerapp

# Report result
reportResults