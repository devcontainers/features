#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" ~/.ghcup/bin/ghc --version | grep 9.2.6

# Report result
reportResults