#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" docker  --version

check "ps" docker  ps

check "run hello world" docker run hello-world

# Asserts specific to manually setting dockerDefaultAddressPool
# TODO

# Report result
reportResults