#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check we have the expected version of mise
check "mise version v2024.5.17" bash -c "mise --version | grep '2024.5.17'"

# Report result
reportResults