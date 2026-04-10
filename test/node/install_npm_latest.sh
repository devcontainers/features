#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# When npmVersion="latest", npm should be upgraded from Node.js bundled version
# Node.js 22 comes with npm 10.x, so latest should be 11+ 
check "npm_version_upgraded" bash -c "npm -v | cut -d. -f1 | awk '\$1 >= 11 { exit 0 } { exit 1 }'"

# Also verify pnpm works as configured
check "pnpm_version" bash -c "pnpm -v | grep 8.8.0"

# Report result
reportResults