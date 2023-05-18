#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "check for aws" aws --version
check "check for gh" gh --version
check "check for azure" az  --version

# Report result
reportResults