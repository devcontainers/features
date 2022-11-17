#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks
check "version" dotnet --version

echo "Validating expected version present..."
check "some major version of dotnet 7 is installed" bash -c "dotnet --version |  grep '7\.[0-9]*\.[0-9]*'"

# Verify current symlink exists and works
check "current link dotnet" /usr/local/dotnet/current/dotnet --info
check "current link sdk" ls -l /usr/local/dotnet/current/sdk

# Report result
reportResults