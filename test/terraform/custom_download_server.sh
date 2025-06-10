#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Check if terraform was installed correctly and it's the expected version
check "terraform installed" terraform --version
check "terraform version matches" terraform --version | grep "1.6.5"

# Report results
reportResults
