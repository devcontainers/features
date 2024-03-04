#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib
# Definition specific tests

check "docker-works" bash -c "docker version | grep Server:"
check "dond-works" bash -c "dond version | grep Server:"
check "docker-orig-works" bash -c "docker.orig version | grep Server:"

check "volumes-does-not-work-without-dond" bash -c "docker.orig run --rm -v $(command -v dond):/dond busybox test ! -f /dond"
check "volumes-works-with-dond" bash -c "docker run --rm -v $(command -v dond):/dond busybox test -f /dond"

# Report result
reportResults
