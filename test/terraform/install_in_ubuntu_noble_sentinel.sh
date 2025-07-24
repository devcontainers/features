#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Check if terraform was installed correctly
check "terraform installed" terraform --version

check "tflint" tflint --version

# Sentinel specific tests
check "sentinel" sentinel --version

# Report result
reportResults

