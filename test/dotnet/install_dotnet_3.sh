#!/bin/bash

set -e

source dev-container-features-test-lib

./test.sh

check "some major version of dotnet 3 is installed" bash -c "dotnet --list-sdks | grep '3\.[0-9]*\.[0-9]*'"

reportResults
