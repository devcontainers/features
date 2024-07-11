#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "cargo version" cargo  --version
check "rustc version" rustc  --version
check "correct rust version" rustup target list | grep aarch64-unknown-linux-gnu


# Report result
reportResults