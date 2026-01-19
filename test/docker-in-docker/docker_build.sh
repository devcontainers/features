#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" docker buildx version
check "docker-build" docker build ./

check "docker compose" bash -c "docker compose version | grep -E '2.[0-9]+.[0-9]+'"
check "docker-compose" bash -c "docker-compose --version | grep -E '2.[0-9]+.[0-9]+'"

check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"

# Report result
reportResults
