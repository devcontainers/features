#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "default-shell-is-zsh-with-no-template" bash -e -x -c "getent passwd $(whoami) | awk -F: '{ print $7 }' | grep '/bin/zsh'; [ ! -e ~/.zshrc ]"

# Report result
reportResults
