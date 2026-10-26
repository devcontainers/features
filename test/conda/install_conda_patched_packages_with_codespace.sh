#!/bin/bash

set -e

source dev-container-features-test-lib

check "running as codespace" test "$(id -un)" = "codespace"
source "$(dirname "$0")/patched_packages_common.sh"

reportResults
