#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "owned-config-sub-directory" bash -c "ls -ld ~/.config/subdirectory | awk '{print $3}' | grep 'devcontainer'"
check "owned-config-directory" bash -c "ls -ld ~/.config | awk '{print $3}' | grep 'devcontainer'"

# Report result
reportResults
