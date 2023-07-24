#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "python3 is installed" python3 --version
check "python is installed" python --version
check "pip is installed" pip --version
check "pip is installed" pip3 --version

# Check that tools can execute
check "pytest" pytest --version

# Check paths in settings
check "current symlink is correct" bash -c "which python | grep /usr/local/python/current/bin/python"
check "current symlink works" /usr/local/python/current/bin/python --version
check "which pytest" bash -c "which pytest | grep /usr/local/py-utils/bin/pytest"

# Report result
reportResults
