#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "default-shell-is-zsh" bash -c "getent passwd $(whoami) | awk -F: '{ print $7 }' | grep '/bin/zsh'"
# check it overrides the ~/.zshrc with default dev containers template
check "default-zshrc-is-dev-container-template" bash -c "cat ~/.zshrc | grep ZSH_THEME | grep devcontainers"

# Report result
reportResults
