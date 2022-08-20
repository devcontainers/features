#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Make sure that libcudnn8 installed correctly
check "libcudnn.so.8" test 1 -eq "$(find /usr -name 'libcudnn.so.8' | wc -l)"

# Make sure that cuda-nvtx-11-<minor version> installed correctly
check "cuda-11+nvtx" test -e '/usr/local/cuda-11/targets/x86_64-linux/include/nvtx3'

# Report result
reportResults
