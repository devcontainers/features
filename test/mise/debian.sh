#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "mise version" mise --version

# Check for correct Debian paths
check "mise in PATH" bash -c "which mise | grep '/usr/local/bin/mise\\|/usr/bin/mise'"

# Report result
reportResults