#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker installed" bash -c "type docker"

# Report results
reportResults
