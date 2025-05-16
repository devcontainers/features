#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "cargo version" cargo  --version
check "rustc version" rustc  --version
check "correct rust version" rustc  --version | grep 1.64.0


# Report result
reportResults