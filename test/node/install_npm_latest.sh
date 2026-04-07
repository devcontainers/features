#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Verify npm is latest version (valid version format)
check "npm_latest_version" bash -c "npm -v | grep -E '^[0-9]+\.[0-9]+\.[0-9]+'"

# Also verify pnpm works as configured
check "pnpm_version" bash -c "pnpm -v | grep 8.8.0"

# Report result
reportResults