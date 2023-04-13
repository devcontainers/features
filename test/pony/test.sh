#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "pony version" ponyc --version

# Report result
reportResults