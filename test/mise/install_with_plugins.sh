#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check for mise
check "mise version" mise --version

# Check for plugins
check "yarn plugin installed" bash -c "mise plugins list | grep yarn"
check "redis plugin installed" bash -c "mise plugins list | grep redis"

# Report result
reportResults