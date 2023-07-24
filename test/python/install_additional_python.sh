#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "python version 3.11 installed as default" bash -c "python --version | grep 3.11"
check "python3 version 3.11 installed as default" bash -c "python3 --version | grep 3.11"
check "python version 3.10.5 installed"  bash -c "ls -l /usr/local/python | grep 3.10.5"
check "python version 3.8 installed"  bash -c "ls -l /usr/local/python | grep 3.8"
check "python version 3.9.13 installed"  bash -c  "ls -l /usr/local/python | grep 3.9.13"

# Check that tools can execute - make sure something didn't get messed up in this scenario
check "pytest" pytest --version

# Check paths in settings
check "current symlink is correct" bash -c "which python | grep /usr/local/python/current/bin/python"
check "current symlink works" /usr/local/python/current/bin/python --version
check "which pytest" bash -c "which pytest | grep /usr/local/py-utils/bin/pytest"

# Report result
reportResults
