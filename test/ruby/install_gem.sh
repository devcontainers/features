#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "gem installed" bash -c "gem install rubocop"

# Report result
reportResults