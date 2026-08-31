#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Terraform Docs specific tests
check "terraform-docs" terraform-docs --version

# Verify the pinned version was installed
check "terraform-docs version is pinned to 0.20.0" bash -c "terraform-docs --version | grep 'v0.20.0'"

# Report result
reportResults
