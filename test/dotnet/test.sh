#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks
check "version" dotnet --version

check "ls /usr/local/dotnet" bash -c 'test "$(ls /usr/local/dotnet | wc -l)" -gt 0'

# Verify current symlink exists and works
check "current link dotnet" /usr/local/dotnet/current/dotnet --info
check "current link sdks" /usr/local/dotnet/current/dotnet --list-sdks
check "current link version" /usr/local/dotnet/current/dotnet --version

# Report result
reportResults
