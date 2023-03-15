#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python  --version
check "pip is installed" pip --version
check "pip is installed" pip3 --version

# Check that tools can execute
check "black" black --version
check "flake8" flake8 --version
check "pylint" pylint --version

# Check paths in settings
check "current symlink is correct" bash -c "which python | grep /usr/local/python/current/bin/python"
check "current symlink works" /usr/local/python/current/bin/python --version
check "which black" bash -c "which black | grep /usr/local/py-utils/bin/black"
check "which flake8" bash -c "which flake8 | grep /usr/local/py-utils/bin/flake8"
check "which pylint" bash -c "which pylint | grep /usr/local/py-utils/bin/pylint"

# Report result
reportResults
