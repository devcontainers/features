#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Always run these checks as the non-root user
user="$(whoami)"

which python3

check "has python" python --version

result=$(python3 -c 'import select; print(select)')
echo "result: $result"

check "select is built-in" bash -c "python3 -c 'import select; print(select)' | grep 'built-in'"

reportResults
