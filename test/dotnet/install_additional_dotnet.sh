#!/bin/bash

set -e

source dev-container-features-test-lib

./test.sh

check "version 6.0.405 installed" bash -c 'dotnet --list-sdks | grep 6.0.405'
check "version 6.0.402 installed" bash -c 'dotnet --list-sdks | grep 6.0.402'
check "version 3.1.416 installed" bash -c 'dotnet --list-sdks | grep 3.1.416'

# Primary version plus 2 additional versions
check "latest version installed" bash -c 'test "$(dotnet --list-sdks | wc -l)" -eq 4'

reportResults
