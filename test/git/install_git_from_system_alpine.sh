#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" git  --version

cd /tmp && git clone https://github.com/devcontainers/feature-starter.git
cd feature-starter

# Report result
reportResults
