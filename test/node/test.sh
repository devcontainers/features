#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" node  --version
echo "location"
echo $(whereis node)
# Report result
reportResults