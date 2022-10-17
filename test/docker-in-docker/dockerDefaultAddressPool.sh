#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "default address pool setting set" ps -ax | grep -E "dockerd.+base=192.168.0.0/16,size=24"

# Report result
reportResults