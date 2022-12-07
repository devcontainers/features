#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "default-shell-is-zsh" getent passwd vscode | awk -F: '{ print $7 }' | grep "/bin/zsh"

# Report result
reportResults
