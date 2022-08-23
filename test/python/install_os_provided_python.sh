#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "python3 is installed" python3 --version
check "python is installed" python --version
check "pip is installed" pip --version
check "pip is installed" pip3 --version

check "node is installed" node --version

# Report result
reportResults