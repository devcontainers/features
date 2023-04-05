#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "no buildx" bash -c "docker buildx version 2>&1 | grep 'not a docker command'"
check "docker-build" docker build ./

# Report result
reportResults
