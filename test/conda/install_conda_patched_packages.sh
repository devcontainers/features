#!/bin/bash

set -e

source dev-container-features-test-lib

check "running as vscode" test "$(id -un)" = "vscode"
source "$(dirname "$0")/patched_packages_common.sh"

reportResults
