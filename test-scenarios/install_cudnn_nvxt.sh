#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "libcudnn.so.8" test 1 -eq "$(find /usr -name 'libcudnn.so.8.3.2' | wc -l)"
check "nvtx" test -e '/usr/local/cuda-11.5/targets/x86_64-linux/include/nvtx3'

# Report result
reportResults
