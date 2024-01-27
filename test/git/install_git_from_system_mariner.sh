#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" git  --version

check "git clone" bash -c "cd /tmp && git clone https://github.com/devcontainers/feature-starter.git"

# Report result
reportResults
