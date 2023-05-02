#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" docker buildx version
check "docker-build" docker build ./

check "not installing compose skips docker-compose v1 install" bash -c "! type docker-compose"

# Report result
reportResults
