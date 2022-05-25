#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "PHP version" php --version
check "Composer version" composer --version

# Report result
reportResults