#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Test: npm "latest" with Node.js 16.x (incompatible scenario)
# Should show compatibility warning and auto-fallback to compatible version (npm 9.x)

# Verify we have Node.js 16.x as expected
check "node_version_16" bash -c "node -v | grep '^v16\.'"

# Check npm is functional after installation attempt
check "npm_works" bash -c "npm --version"

# Verify npm version fell back to compatible version for Node 16.x (should be npm 8.x)
check "npm_fallback_version" bash -c "
    NPM_MAJOR=\$(npm --version | cut -d. -f1)
    if [ \$NPM_MAJOR -eq 8 ]; then
        echo 'npm auto-fell back to version 8.x (compatible with Node 16.x)'
        exit 0
    else
        echo 'npm version \$NPM_MAJOR.x - fallback may not have worked correctly'
        exit 1
    fi
"

# Report result
reportResults