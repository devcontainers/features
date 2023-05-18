#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Extension-specific tests
check "az.resources" pwsh -Command "(Get-Module -ListAvailable -Name Az.Resources).Version.ToString()"
check "az.storage" pwsh -Command "(Get-Module -ListAvailable -Name Az.Storage).Version.ToString()"

# Report result
reportResults
