#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Test stable version installation on AlmaLinux
check "pwsh is installed" bash -c "command -v pwsh"
check "pwsh version is stable (not preview)" bash -c "pwsh --version | grep -v 'preview'"
check "pwsh can execute basic command" bash -c "pwsh -Command 'Write-Output Hello'"

# Report result
reportResults
