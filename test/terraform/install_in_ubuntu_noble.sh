#!/bin/bash

set -e

# Import test library
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Check if terraform was installed correctly
check "terraform installed" terraform --version

check "tflint" tflint --version

# Report results
reportResults

