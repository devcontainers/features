#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Check if terraform was installed correctly
check "terraform installed" terraform --version

check "tflint" tflint --version

# Report results
reportResults

