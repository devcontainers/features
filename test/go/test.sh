#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" go version
check "revive version" revive --version
check "revive is installed at correct path" bash -c "which revive | grep /go/bin/revive"

# Report result
reportResults