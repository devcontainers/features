#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "devcontainer-info" sh -c "devcontainer-info | grep test-build"

# Report result
reportResults
