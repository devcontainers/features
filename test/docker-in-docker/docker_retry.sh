#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" docker buildx version
check "docker-ps" docker ps

sleep 5s

# Stop docker
pkill dockerd
pkill containerd

sleep 5s

set +e
    docker_ok_code="$(docker info > /dev/null 2>&1; echo $?)"
set -e

check "docker-not-running" bash -c "[[ ${docker_ok_code} == 1 ]]"

#  Testing retry logic
./test-scripts/docker-test-init.sh

check "docker-started-after-retries" docker ps

# Report result
reportResults
