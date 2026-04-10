#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "cuda version" test -d /usr/local/cuda-12.5

# Check installation of cuda-libraries-12-<version>
check "libcudart.so.12" test 1 -eq "$(find /usr -name 'libcudart.so.12' | wc -l)"
check "libcublas.so.12" test 1 -eq "$(find /usr -name 'libcublas.so.12' | wc -l)"
check "libcublasLt.so.12" test 1 -eq "$(find /usr -name 'libcublasLt.so.12' | wc -l)"
check "libcufft.so.11" test 1 -eq "$(find /usr -name 'libcufft.so.11' | wc -l)"
check "libcurand.so.10" test 1 -eq "$(find /usr -name 'libcurand.so.10' | wc -l)"
check "libcusolver.so.11" test 1 -eq "$(find /usr -name 'libcusolver.so.11' | wc -l)"
check "libcusparse.so.12" test 1 -eq "$(find /usr -name 'libcusparse.so.12' | wc -l)"

# Report result
reportResults
