#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Test preview version installation on Debian
check "pwsh is installed" bash -c "command -v pwsh"
check "pwsh version is preview" bash -c "pwsh --version | grep -iE 'preview|rc\.[0-9]+'"
check "pwsh can execute basic command" bash -c "pwsh -Command 'Write-Output Hello'"

# Report result
reportResults
