#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"

check "docker-buildx" docker buildx version
check "docker-build" docker build ./

check "installs docker-compose v1 install" bash -c "type docker-compose"

check "Not installing compose-switch by default" bash -c "[[ ! -f /usr/local/bin/compose-switch ]]"

# Report result
reportResults
