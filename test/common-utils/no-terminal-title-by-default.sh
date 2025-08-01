#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release

# Make sure bashrc is applied
source /root/.bashrc

check "check_term_is_not_set" test !"$TERM"
check "check_prompt_command_not_set" test !"$PROMPT_COMMAND"

# Report result
reportResults