#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libcudnn8 (8.3.2)
check "libcudnn.so.8.3.2" test 1 -eq "$(find /usr -name 'libcudnn.so.8.3.2' | wc -l)"

# Check installation of cuda-nvtx-11-5 (11.5)
check "cuda-11-5+nvtx" test -e '/usr/local/cuda-11.5/targets/x86_64-linux/include/nvtx3'

# Report result
reportResults
    