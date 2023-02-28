#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Make sure .NET is installed
check "info" dotnet --info
check "list-sdks" dotnet --list-sdks
check "version" dotnet --version

# Make sure the symlink works
check "current link info" /usr/local/dotnet/current/dotnet --info
check "current link sdk directory" ls -l /usr/local/dotnet/current/sdk

# Report result
reportResults
