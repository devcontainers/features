#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "info" dotnet --info
check "list-sdks" dotnet --list-sdks
check "version" dotnet --version

# Make sure the symlink works
check "current link info" /usr/local/dotnet/current/dotnet --info
check "current link sdk directory" ls -l /usr/local/dotnet/current/sdk

# TODO: Installer script defaults to .NET 6 as that's LTS. Update this test or remove it.
# echo "Validating expected version present..."
# check "some major version of dotnet 7 is installed" bash -c "dotnet --version |  grep '7\.[0-9]*\.[0-9]*'"

# Report result
reportResults
