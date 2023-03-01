#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# some runtime installed
check "runtime" bash -c 'test "$(dotnet --list-runtimes | wc -l)" -gt 0'

# no sdk installed
check "no sdk" bash -c 'test "$(dotnet --list-sdks | wc -l)" -eq 0'

# Report result
reportResults
