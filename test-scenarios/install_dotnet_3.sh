#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "dotnet sdks" dotnet --list-sdks
check "some major version of dotnet 3 is installed" dotnet --list-sdks |  grep '3\.[0-9]*\.[0-9]*'
check "dotnet version 3 installed"  ls -l /usr/local/dotnet | grep 3

# Report result
reportResults
