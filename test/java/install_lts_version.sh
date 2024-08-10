#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version LTS installed as default" grep "LTS" <(java --version)

# Report result
reportResults
