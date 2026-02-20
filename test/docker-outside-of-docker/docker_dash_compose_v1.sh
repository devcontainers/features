#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests - v1 should only have docker-compose, not docker compose plugin
check "docker-compose" bash -c "docker-compose --version | grep -E '1.[0-9]+.[0-9]+'"
check "no docker compose plugin" bash -c "if command -v docker >/dev/null 2>&1; then ! docker compose version >/dev/null 2>&1; else true; fi"

# Report result
reportResults
