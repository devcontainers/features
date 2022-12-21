#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" gh --version

# Report result
reportResults
