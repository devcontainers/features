#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "current user" bash -c "whoami"

check "version" rvm  --version

check "ruby version" ruby  --version

# Report result
reportResults