#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Verify that desktop-init.sh correctly passes through commands.
# Previously, the heredoc in install.sh did not escape $1 and $@, causing them to expand
# to empty strings at install time, so any command passed to desktop-init.sh was silently ignored.

check "command is passed through and executed" \
    bash -c "result=\$(/usr/local/share/desktop-init.sh echo 'passthrough-test-token' 2>/dev/null) && echo \"\$result\" | grep -q 'passthrough-test-token'"

# Report result
reportResults
