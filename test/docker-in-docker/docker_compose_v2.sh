#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests

check "docker compose" bash -c "docker compose version | grep -E '2.[0-9]+.[0-9]+'"
check "docker-compose" bash -c "docker-compose --version | grep -E '2.[0-9]+.[0-9]+'"
check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"

check "Not installing compose-switch by default" bash -c "[[ ! -f /usr/local/bin/compose-switch ]]"

# Report result
reportResults
