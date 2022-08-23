#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java" java --version
check "gradle" gradle --version
check "maven" mvn --version

# Report result
reportResults
