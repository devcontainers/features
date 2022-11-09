#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version 11 installed as default" grep "11\." <(java --version)
check "java version 17 installed" grep "^17\." <(ls /usr/local/sdkman/candidates/java)
check "java version 8 installed" grep "^8\." <(ls /usr/local/sdkman/candidates/java)

# Report result
reportResults
