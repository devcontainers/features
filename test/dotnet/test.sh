#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks

check "some major version of dotnet 6 is installed" dotnet --list-sdks |  grep '6\.[0-9]*\.[0-9]*'

# Report result
reportResults