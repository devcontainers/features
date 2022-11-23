#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "shh-init-exists" bash -c "ls /usr/local/share | grep ssh-init.sh"
check "shhd-log-exists" bash -c "ls /tmp | grep sshd.log"
check "shhd-log-contents" bash -c "cat /tmp/sshd.log | grep 'Starting OpenBSD Secure Shell server sshd'"

# Report result
reportResults