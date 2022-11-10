#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "dotnet sdks" dotnet --list-sdks
check "some major version of dotnet 7 is installed" dotnet --list-sdks |  grep '7\.[0-9]*\.[0-9]*'
check "dotnet version 7 installed"  ls -l /usr/share/dotnet/sdk | grep '7\.[0-9]*\.[0-9]*'


# Report result
reportResults
