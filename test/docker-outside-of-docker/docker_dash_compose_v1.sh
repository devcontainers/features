#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker compose" bash -c "docker compose version | grep 'Docker Compose version v2'"
check "docker-compose" bash -c "docker-compose --version | grep '^1.'"

# Report result
reportResults
