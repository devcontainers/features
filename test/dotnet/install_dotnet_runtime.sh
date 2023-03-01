#!/bin/bash

set -e

source dev-container-features-test-lib

# Some runtime installed
check "runtime" bash -c 'test "$(dotnet --list-runtimes | wc -l)" -gt 0'

# No sdk installed
check "no sdk" bash -c 'test "$(dotnet --list-sdks | wc -l)" -eq 0'

reportResults
