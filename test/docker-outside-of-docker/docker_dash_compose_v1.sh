#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-compose" bash -c "docker-compose --version | grep -E '1.[0-9]+.[0-9]+'"

# Report result
reportResults
