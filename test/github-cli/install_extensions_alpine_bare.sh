#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Unlike the devcontainers base image, a bare Alpine image ships neither git nor bash nor a
# non-root user, so this exercises the installer's own dependency handling and its fallback
# to installing extensions for root
check "gh-version" gh --version
check "git-installed" bash -c "command -v git"
check "bash-installed" bash -c "command -v bash"

check "gh-extension-installed" bash -c "gh extension list | grep -q 'dlvhdr/gh-dash'"

# Report result
reportResults
