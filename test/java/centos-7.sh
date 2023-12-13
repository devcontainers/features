#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version openjdk 19 installed" grep "openjdk 19." <(java --version)

# Report result
reportResults
