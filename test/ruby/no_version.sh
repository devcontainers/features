#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "rvm" rvm --version
check "no rvm rubies" bash -c "rvm list | fgrep 'No rvm rubies installed yet'"

# Report result
reportResults
