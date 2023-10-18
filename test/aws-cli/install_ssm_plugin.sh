#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" aws --version

# verify Session manager as https://docs.aws.amazon.com/systems-manager/latest/userguide/install-plugin-verify.html
check "The Session Manager plugin is installed successfully" session-manager-plugin

# Report result
reportResults