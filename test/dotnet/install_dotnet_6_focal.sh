#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

./test.sh

check "some major version of dotnet 6 is installed" bash -c "dotnet --list-sdks | grep '6\.[0-9]*\.[0-9]*'"

# Report result
reportResults
