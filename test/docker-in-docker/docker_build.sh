#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" docker buildx version
check "docker-build" docker build ./

check "installs docker-compose v2 install" bash -c "type docker-compose"
check
# Report result
reportResults
