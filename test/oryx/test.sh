#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo $PATH
check "Oryx version" oryx --version

# Report result
reportResults