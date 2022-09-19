#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "java version 18 installed as default" java --version | grep 18

# Report result
reportResults
