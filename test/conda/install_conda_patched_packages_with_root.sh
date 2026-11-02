#!/bin/bash

set -e

source dev-container-features-test-lib

check "running as root" test "$(id -u)" = "0"
source "$(dirname "$0")/patched_packages_common.sh"

reportResults
