#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version 3.9 installed"  ls -1 /usr/local/python/ | grep 3.9
check "version 3.8 installed"  ls -1 /usr/local/python/ | grep 3.8

check "3.9 alias to python on path" python  --version | grep 3.9

# Report result
reportResults
