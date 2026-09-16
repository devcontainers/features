#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker installed" bash -c "type docker"
check "docker-buildx" docker buildx version
check "moby-cli installed" bash -c "dpkg -l moby-cli"
check "moby-engine installed" bash -c "dpkg -l moby-engine"

# Report result
reportResults
