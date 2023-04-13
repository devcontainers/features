#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "pony-version-0-is-installed" bash -c "ponyc --version | grep '0\.'"
check "ponyc-version" ponyc --version

# Report result
reportResults
