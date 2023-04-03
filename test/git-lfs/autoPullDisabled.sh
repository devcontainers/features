#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "target file exists" cat big-file-1.txt
check "lfs file has not been expanded" cat "big-file-1.txt" | grep "git-lfs\.github\.com"

reportResults