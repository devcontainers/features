#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "check for node" node --version
check "check for java" java --version
check "check for rust" rustc  --version

# Report result
reportResults