#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Verify npm is installed with specific version 10.8.0
check "npm_specific_version" bash -c "npm -v | grep '^10.8.0'"

# Report result
reportResults