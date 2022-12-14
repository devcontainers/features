#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
# .oh-my-zsh folder would only exist if user detection worked
check "non-root user" ls /home/node/.oh-my-zsh

# Report result
reportResults