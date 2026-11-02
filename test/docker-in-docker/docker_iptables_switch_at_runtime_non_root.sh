#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "entrypoint runs as codespace" bash -c "test \"$(id -un)\" = codespace"
check "iptables uses legacy backend" bash -c "iptables --version | grep -q '(legacy)'"

# Report result
reportResults