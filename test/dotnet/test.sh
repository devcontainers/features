#!/bin/bash

set -e

source dev-container-features-test-lib

check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks
check "version" dotnet --version

# Verify current symlink exists and works
check "current link dotnet" /usr/local/dotnet/current/dotnet --info
check "current link sdks" /usr/local/dotnet/current/dotnet --list-sdks
check "current link version" /usr/local/dotnet/current/dotnet --version

# Verify installation location
check "dotnet in /usr/local/dotnet" bash -c 'test "$(ls /usr/local/dotnet | wc -l)" -gt 0'
check "sdks in /usr/local/dotnet/sdk" bash -c 'test "$(ls /usr/local/dotnet/current/sdk | wc -l)" -gt 0'

reportResults
