#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" java  --version

# Check env
check "JAVA_HOME is set correctly" echo $JAVA_HOME | grep "/usr/local/sdkman/candidates/java/current"

# Report result
reportResults
