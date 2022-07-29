#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks

# Report result
reportResults