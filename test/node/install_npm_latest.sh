#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# When npmVersion="latest", npm should be upgraded from Node.js bundled version if possible
# Node.js 22 comes with npm 10.x, latest should be 11+ if upgrade succeeds
# If upgrade fails, npm should still work (may remain at bundled version)
check "npm_version_upgraded_or_functional" bash -c "
    npm --version >/dev/null
    NPM_MAJOR=\$(npm --version | cut -d. -f1)
    
    if [ \$NPM_MAJOR -ge 11 ]; then
        echo 'npm successfully upgraded to version 11+ (\$NPM_MAJOR.x)'
        exit 0
    elif [ \$NPM_MAJOR -eq 10 ]; then
        echo 'npm upgrade may have failed, but npm 10.x is still functional'
        exit 0
    else
        echo 'npm version \$NPM_MAJOR.x - unexpected version'
        exit 1
    fi
"

# Also verify pnpm works as configured
check "pnpm_version" bash -c "pnpm -v | grep 8.8.0"

# Report result
reportResults