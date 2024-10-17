#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"

check "docker-buildx" docker buildx version
check "docker-build" docker build ./

check "installs docker-compose v2 install" bash -c "type docker-compose"
check "docker compose" bash -c "docker compose version | grep -E '2.[0-9]+.[0-9]+'"
check "docker-compose" bash -c "docker-compose --version | grep -E '2.[0-9]+.[0-9]+'"

check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"

# Report result
reportResults