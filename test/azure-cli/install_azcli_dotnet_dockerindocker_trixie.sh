#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

check "version" az  --version

check "docker installed" bash -c "type docker"

# Report result
reportResults