#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "python version 3.10.5 installed as default" python -v | grep 3.10.5
check "python version 3.8.13 installed"  ls -l /usr/local/python | grep 3.8.13
check "python version 3.9.13 installed"  ls -l /usr/local/python | grep 3.9.13

# Report result
reportResults
