#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# The feature was invoked with version=none on a base image that already ships
# Ruby. ruby-build should still be installed so additional versions can be added.
check "ruby version" ruby --version
check "gem version" gem --version
check "ruby-build available" ruby-build --version

# Report result
reportResults
