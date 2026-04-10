#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# When npmVersion is "none", npm should not be updated from node's bundled version
check "npm_not_updated" bash -c "npm --version"

# Report result
reportResults