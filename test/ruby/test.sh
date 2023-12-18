#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "ruby version" ruby  --version

check "gem version" gem --version

# Report result
reportResults