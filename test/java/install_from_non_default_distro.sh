#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version openjdk 11 installed" grep "openjdk 11." <(java --version)

# Report result
reportResults
