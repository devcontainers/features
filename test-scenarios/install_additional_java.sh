#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version 17 installed as default" java --version | grep 17
check "java version 11 installed"  ls /usr/local/sdkman/candidates/java  | grep 11
check "java version 8 installed"  ls /usr/local/sdkman/candidates/java | grep 8


# Report result
reportResults
