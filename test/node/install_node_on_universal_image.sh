#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version_on_path" bash -c "node -v | grep 'v19.1.0'"
check "pnpm" pnpm -v

# Report result
reportResults
