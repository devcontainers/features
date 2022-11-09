#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version 18 installed" grep "18" <(java --version)

# Report result
reportResults
