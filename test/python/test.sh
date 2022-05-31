#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python  --version
check "lzma" python -c "import lzma"

# Report result
reportResults
