#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "desktop-init-exists" bash -c "ls /usr/local/share | grep desktop-init.sh"
check "log-exists" bash -c "ls /tmp | grep container-init.log"
check "log-contents" bash -c "cat /tmp/container-init.log | grep 'Xtigervnc started'"
check "fluxbox-exists" bash -c "ls -la ~ | grep .fluxbox"

# Report result
reportResults