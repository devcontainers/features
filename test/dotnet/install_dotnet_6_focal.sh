#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "dotnet sdks" dotnet --list-sdks
check "some major version of dotnet 6 is installed" bash -c "dotnet --list-sdks |  grep '6\.[0-9]*\.[0-9]*'"
check "dotnet version 6 installed"  bash -c "ls -l /usr/share/dotnet/sdk | grep '6\.[0-9]*\.[0-9]*'"

# Verify current symlink exists and works
check "current link dotnet" /usr/local/dotnet/current/dotnet --info
check "current link sdk" ls -l /usr/local/dotnet/current/sdk

# Report result
reportResults
