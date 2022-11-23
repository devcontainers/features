#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" docker  --version
check "docker-init-exists" bash -c "ls /usr/local/share/docker-init.sh"
check "docker-ps" bash -c "docker ps"

# Report result
reportResults