#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

check "bicep" bicep --version

# Report result
reportResults