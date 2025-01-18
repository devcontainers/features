#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# # Check installation of libcudnn9-cuda-12 (9.4.0)
check "libcudnn.so.9.5.0" test 1 -eq "$(find /usr -name 'libcudnn.so.9.5.0' | wc -l)"

# Check installation of cuda-nvtx-12-5 (12.5)
check "cuda-12-5+nvtx" test -e '/usr/local/cuda-12.5/targets/x86_64-linux/include/nvtx3/'

# Report result
reportResults
