#!/bin/bash

set -e

source dev-container-features-test-lib

check "running as codespace" test "$(id -un)" = "codespace"
check "codespace UID is 1000" test "$(id -u)" = "1000"
check "codespace GID is 1000" test "$(id -g)" = "1000"
check "ubuntu user removed" bash -c '! id ubuntu'
check "container user is codespace" test "$(ps -o uid= -p 1 | tr -d ' ')" = "1000"
source "$(dirname "$0")/patched_packages_common.sh"

reportResults
