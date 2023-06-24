#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "terraform" terraform -version

check "tflint" tflint --version

# Report result
reportResults