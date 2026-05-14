#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "ruby version" ruby  --version
check "gem version" gem --version

check "ruby version uses dot separator" bash -c "ruby --version | grep -oP '\d+\.\d+\.\d+'"

# Report result
reportResults