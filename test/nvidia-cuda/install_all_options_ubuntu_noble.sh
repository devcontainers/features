#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check installation of libcudnn9
check "libcudnn.so.9" test 1 -eq "$(find /usr -name 'libcudnn.so.9' | wc -l)"

# Check installation of libcudnn9-dev
check "cudnn.h" test 1 -eq "$(find /usr -name 'cudnn.h' | wc -l)"

# Check installation of cuda-nvtx-12-<version>
check "cuda-12+nvtx" test -e '/usr/local/cuda-12.5/targets/x86_64-linux/include/nvtx3'

# Check installation of cuda-nvcc-12-<version>
check "cuda-12+nvcc" test -e '/usr/local/cuda-12.5/bin/nvcc'

# Report result
reportResults

