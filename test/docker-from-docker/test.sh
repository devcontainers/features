#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" docker  --version
check "docker-init-exists" bash -c "ls /usr/local/share | grep docker-init.sh"

# Report result
reportResults