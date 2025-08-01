#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libcudnn9
check "libcudnn.so.9" test 1 -eq "$(find /usr -name 'libcudnn.so.9' | wc -l)"

# Check installation of cuda-nvtx-12-3 (12.3)
check "cuda-12-3+nvtx" test -e '/usr/local/cuda-12.3/targets/x86_64-linux/include/nvtx3/'

# Report result
reportResults
