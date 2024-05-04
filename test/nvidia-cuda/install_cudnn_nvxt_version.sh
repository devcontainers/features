#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libcudnn8 (8.5.0)
check "libcudnn.so.8.5.0" test 1 -eq "$(find /usr -name 'libcudnn.so.8.5.0' | wc -l)"

# Check installation of cuda-nvtx-11-7 (11.7)
check "cuda-11-7+nvtx" test -e '/usr/local/cuda-11.7/targets/x86_64-linux/include/nvtx3'

# Report result
reportResults
    