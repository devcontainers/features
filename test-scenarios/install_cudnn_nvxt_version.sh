#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Make sure that libcudnn8 (8.3.2) installed correctly
check "libcudnn.so.8.3.2" test 1 -eq "$(find /usr -name 'libcudnn.so.8.3.2' | wc -l)"

# Make sure that cuda-nvtx-11-5 (11.5) installed correctly
check "cuda-11-5+nvtx" test -e '/usr/local/cuda-11.5/targets/x86_64-linux/include/nvtx3'

# Report result
reportResults
