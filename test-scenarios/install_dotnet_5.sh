#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "dotnet sdks" dotnet --list-sdks
check "some major version of dotnet 5 is installed" dotnet --list-sdks |  grep '5\.[0-9]*\.[0-9]*'
check "dotnet version 5 installed"  ls -l /usr/local/dotnet | grep 5


# Report result
reportResults
