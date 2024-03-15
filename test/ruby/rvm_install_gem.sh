#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "current user" bash -c "whoami"

check "current ruby" bash -c "which ruby"

check "gem installed" bash -c "gem install rubocop"

# Report result
reportResults