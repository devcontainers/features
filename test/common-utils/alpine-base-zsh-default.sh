#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "alpine default shell zsh" \
  bash -c "getent passwd $(whoami) | awk -F : '{ print $7 }' | grep '/bin/zsh'"

# Report result
reportResults
