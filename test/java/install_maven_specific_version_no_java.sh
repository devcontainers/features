#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "maven version" grep "Apache Maven 3.8.8" <(mvn --version)

# Report result
reportResults
