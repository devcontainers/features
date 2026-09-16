#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" gh --version

# "2.99" is a partial version, so it should resolve to the newest 2.99.x release - and in
# particular must not match 2.9.x or the numerically larger 2.101.x
check "resolved-partial-version" bash -c "gh --version | grep -qE '^gh version 2\.99\.[0-9]+'"

# Report result
reportResults
