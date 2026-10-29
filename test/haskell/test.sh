#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" ~/.ghcup/bin/ghcup list

# Report result
reportResults