#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "desktop-init-exists" bash -c "ls /usr/local/share/desktop-init.sh"
check "log-exists" bash -c "ls /tmp/container-init.log"
check "fluxbox-exists" bash -c "ls -la ~/.fluxbox"

# Report result
reportResults