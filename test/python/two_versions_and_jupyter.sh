#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

ls -la /usr/local/python

check "python version 3.10.* installed as default" python --version | grep 3.10
check "python3 version 3.10.* installed as default" python3 --version | grep 3.10
check "python version 3.9.* installed"  ls -l /usr/local/python | grep 3.9

check "jupyter installed" jupyter lab --version

# Report result
reportResults
