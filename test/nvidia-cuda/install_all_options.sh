#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libcudnn8
check "libcudnn.so.8" test 1 -eq "$(find /usr -name 'libcudnn.so.8' | wc -l)"

# Check installation of libcudnn8-dev
check "cudnn.h" test 1 -eq "$(find /usr -name 'cudnn.h' | wc -l)"

# Check installation of cuda-nvtx-11-<version>
check "cuda-11+nvtx" test -e '/usr/local/cuda-11/targets/x86_64-linux/include/nvtx3'

# Check installation of cuda-nvcc-11-<version>
check "cuda-11+nvcc" test -e '/usr/local/cuda-11/bin/nvcc'

# Report result
reportResults
