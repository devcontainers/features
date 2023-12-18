#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "current user" bash -c "whoami"

check "ruby installed" bash -c "ruby --version | grep 3.0.6"

# Report result
reportResults
