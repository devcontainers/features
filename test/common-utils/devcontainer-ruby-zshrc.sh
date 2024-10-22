#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "configure-zshrc-without-overwrite" bash -c "grep 'rbenv init -' ~/.zshrc"

# Report result
reportResults
