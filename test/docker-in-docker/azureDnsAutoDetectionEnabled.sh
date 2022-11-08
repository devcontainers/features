#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "dns flag should be present" bash -c "ps -ax | grep -E "dockerd.+\-\-dns""

# Report result
reportResults