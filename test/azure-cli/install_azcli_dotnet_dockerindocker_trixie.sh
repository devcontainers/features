#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

check "version" az  --version


# Report result
reportResults