#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "ruby version" ruby  --version
check "gem version" gem --version

echo "location"
echo $(whereis ruby)

# Report result
reportResults