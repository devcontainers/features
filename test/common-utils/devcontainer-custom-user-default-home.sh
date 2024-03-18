#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "user is customUser" grep customUser <(whoami)
check "home is /home/customUser" grep "/home/customUser" <(getent passwd customUser | cut -d: -f6)

# Report result
reportResults
