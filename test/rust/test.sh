#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "cargo version" cargo  --version
check "rustc version" rustc  --version


# Report result
reportResults