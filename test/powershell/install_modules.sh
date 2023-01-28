#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Extension-specific tests
check "az.resources" pwsh -Command "Get-Module -name az.resource"
check "az.storage" pwsh -Command "Get-Module -name az.storage"

# Report result
reportResults