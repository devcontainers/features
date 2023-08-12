#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature specific tests
check "docker-ps" bash -c "docker ps"
check "docker-login" bash -c "docker login"

# Report result
reportResults