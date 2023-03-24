#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

check "composer-version" composer --version

# Report result
reportResults
