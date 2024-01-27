#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" git  --version

# Ensure git clone works, i.e. ca-certificates are installed.
check "git clone" bash -c "cd /tmp && git clone https://github.com/devcontainers/feature-starter.git"

# Report result
reportResults
