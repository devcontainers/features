#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "jupyter lab version" jupyter lab --version

# Report result
reportResults
