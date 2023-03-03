#!/bin/bash

set -e

source dev-container-features-test-lib

./test.sh

check "lts version installed" bash -c 'test "$(dotnet --list-sdks | wc -l)" -eq 1'

reportResults
