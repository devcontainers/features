#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "dotnet version 6.0.301 installed as default" bash -c "dotnet --version | grep 6.0.301"
check "dotnet version 5.0 installed"  bash -c "ls -l /usr/local/dotnet | grep 5.0"
check "dotnet version 3.1.420 installed"  bash -c "ls -l /usr/local/dotnet | grep 3.1.420"

# Verify current symlink exists and works
check "current link dotnet" /usr/local/dotnet/current/dotnet --info
check "current link sdk" ls -l /usr/local/dotnet/current/sdk

# Report result
reportResults
