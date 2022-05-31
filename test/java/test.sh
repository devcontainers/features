#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" java  --version
echo "location"
echo $(whereis java)
# Report result
reportResults