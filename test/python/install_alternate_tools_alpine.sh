#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" python  --version
check "pip is installed" pip --version
check "pip is installed" pip3 --version

# Check that tools can execute
check "bandit" bandit --version
check "mypy" mypy --version
check "pipenv" pipenv --version
check "pytest" pytest --version
check "ruff" ruff --version
check "virtualenv" virtualenv --version

# Check paths in settings
check "current symlink is correct" bash -c "which python | grep /usr/local/python/current/bin/python"
check "current symlink works" /usr/local/python/current/bin/python --version
check "which bandit" bash -c "which bandit | grep /usr/local/py-utils/bin/bandit"
check "which mypy" bash -c "which mypy | grep /usr/local/py-utils/bin/mypy"
check "which pipenv" bash -c "which pipenv | grep /usr/local/py-utils/bin/pipenv"
check "which pytest" bash -c "which pytest | grep /usr/local/py-utils/bin/pytest"
check "which ruff" bash -c "which ruff | grep /usr/local/py-utils/bin/ruff"
check "which virtualenv" bash -c "which virtualenv | grep /usr/local/py-utils/bin/virtualenv"

# Report result
reportResults
