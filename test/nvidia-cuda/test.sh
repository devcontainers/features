#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "libcudart.so.11.0" test 1 -eq "$(find /usr -name 'libcudart.so.11.0' | wc -l)"
check "libcublas.so.11" test 1 -eq "$(find /usr -name 'libcublas.so.11' | wc -l)"
check "libcublasLt.so.11" test 1 -eq "$(find /usr -name 'libcublasLt.so.11' | wc -l)"
check "libcufft.so.10" test 1 -eq "$(find /usr -name 'libcufft.so.10' | wc -l)"
check "libcurand.so.10" test 1 -eq "$(find /usr -name 'libcurand.so.10' | wc -l)"
check "libcusolver.so.11" test 1 -eq "$(find /usr -name 'libcusolver.so.11' | wc -l)"
check "libcusparse.so.11" test 1 -eq "$(find /usr -name 'libcusparse.so.11' | wc -l)"

# TODO: Move these to a new scenario for this feature
# check "libcudnn.so.8" test 1 -eq "$(find /usr -name 'libcudnn.so.8' | wc -l)"
# check "nvtx" test -e '/usr/local/cuda-11.7/targets/x86_64-linux/include/nvtx3'

# Report result
reportResults
