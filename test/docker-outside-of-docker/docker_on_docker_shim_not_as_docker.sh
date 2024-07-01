#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib
# Definition specific tests

check "volumes-does-not-work-by-default" bash -c "docker run --rm -v $(command -v dond):/dond busybox test ! -f /dond"
check "volumes-works-with-dond" bash -c "dond run --rm -v $(command -v dond):/dond busybox test -f /dond"

# Report result
reportResults
