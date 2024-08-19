#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release

# Make sure bashrc is applied
source /root/.bashrc

check "check_term_is_set" test "$TERM" = "xterm"
check "check_term_is_set" test "$PROMPT_COMMAND" = "precmd"

# Report result
reportResults