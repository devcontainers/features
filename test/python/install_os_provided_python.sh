#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "python3 is installed" python3 --version
check "python is installed" python --version
check "pip is installed" pip --version
check "pip is installed" pip3 --version

# Check that tools can execute
check "autopep8" autopep8 --version
check "black" black --version
check "flake8" flake8 --version
check "mypy" mypy --version
check "pylint" pylint --version

# Check paths in settings
check "current symlink is correct" bash -c "which python | grep /usr/local/python/current/bin/python"
check "current symlink works" /usr/local/python/current/bin/python --version
check "which autopep8" bash -c "which autopep8 | grep /usr/local/py-utils/bin/autopep8"
check "which black" bash -c "which black | grep /usr/local/py-utils/bin/black"
check "which flake8" bash -c "which flake8 | grep /usr/local/py-utils/bin/flake8"
check "which mypy" bash -c "which mypy | grep /usr/local/py-utils/bin/mypy"
check "which pylint" bash -c "which pylint | grep /usr/local/py-utils/bin/pylint"

# Report result
reportResults
