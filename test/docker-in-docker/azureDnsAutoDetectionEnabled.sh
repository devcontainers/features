#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dns flag should be present" ps -ax | grep -v grep | grep -E "dockerd.+\-\-dns"

# Report result
reportResults