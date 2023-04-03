#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "target file exists" cat big-file-1.txt
check "lfs file has been expanded" cat "big-file-1.txt" | grep "this is test file 1"

reportResults