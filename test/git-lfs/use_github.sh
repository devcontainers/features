#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "git-lfs" bash -c "git-lfs --version"

reportResults