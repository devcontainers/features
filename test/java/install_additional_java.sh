#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version 18 installed as default" grep "18" <(java --version)
check "java version 11 installed" grep "11" <(ls /usr/local/sdkman/candidates/java)
check "java version 8 installed" grep "8" <(ls /usr/local/sdkman/candidates/java)

# Report result
reportResults
