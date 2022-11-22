#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "go-version" bash -c "go version | grep 1.19"

# Report result
reportResults
