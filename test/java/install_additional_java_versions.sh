#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version openjdk 25 installed as default" grep "openjdk 25\." <(java --version)
check "java version 21 installed as additional version" grep "^21\." <(ls /usr/local/sdkman/candidates/java)

# Report result
reportResults