#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "docker buildx" bash -c "docker buildx version"
check "docker compose" bash -c "docker compose version"
check "docker-compose" bash -c "docker-compose --version"

check "docker-ps" bash -c "docker ps >/dev/null"

# Report result
reportResults