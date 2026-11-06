#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "mise version" mise --version
check "mise activate command" mise activate bash
check "mise plugins command" mise plugins list

# Report result
reportResults