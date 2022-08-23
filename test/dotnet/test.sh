#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dotnet" dotnet --info
check "sdks" dotnet --list-sdks
check "version" dotnet --version

echo "Validating expected version present..."
check "some major version of dotnet 6 is installed" dotnet --version |  grep '6\.[0-9]*\.[0-9]*'

# Report result
reportResults