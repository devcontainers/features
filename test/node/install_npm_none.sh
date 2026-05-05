#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# When npmVersion is "none", npm should not be updated from node's bundled version
check "npm_not_updated" bash -c '
    npm --version >/dev/null

    NODE_MAJOR=$(node -p "process.versions.node.split(\".\")[0]")
    NPM_MAJOR=$(npm --version | cut -d. -f1)

    case "$NODE_MAJOR" in
        16) EXPECTED_NPM_MAJOR=8 ;;
        18|20|22) EXPECTED_NPM_MAJOR=10 ;;
        24) EXPECTED_NPM_MAJOR=11 ;;
        *)
            echo "Unsupported Node major for bundled npm assertion: $NODE_MAJOR"
            exit 1
            ;;
    esac

    [ "$NPM_MAJOR" = "$EXPECTED_NPM_MAJOR" ]
'

# Report result
reportResults