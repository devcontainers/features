#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

check "pwsh is installed" bash -c "command -v pwsh"
check "pwsh version is LTS (not preview)" bash -c "pwsh --version | grep -v 'preview'"

# Extension-specific tests
check "az.resources" pwsh -Command "(Get-Module -ListAvailable -Name Az.Resources).Version.ToString()"
check "az.storage" pwsh -Command "(Get-Module -ListAvailable -Name Az.Storage).Version.ToString()"
check "profile" pwsh -Command 'if (-not $env:ProfileLoaded) {Write-Host "Profile not loaded, envvar '\''ProfileLoaded'\'' does not exist"; exit 1 } else {Write-Host "Profile Loaded: $($env:ProfileLoaded)"; exit 0 }'

# Report result
reportResults
