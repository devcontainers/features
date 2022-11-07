#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dns flag should not be present" test ! "$(ps -ax | grep -E 'dockerd.+\-\-dns')"

# Report result
reportResults