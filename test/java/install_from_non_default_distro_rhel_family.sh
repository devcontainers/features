#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version openjdk 21 installed" grep "openjdk 21." <(java --version)

# Report result
reportResults
