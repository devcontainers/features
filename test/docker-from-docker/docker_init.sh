#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "docker-init-exists" bash -c "ls /usr/local/share | grep docker-init.sh"
check "log-exists" bash -c "ls /tmp | grep vscr-docker-from-docker.log"
check "log-contents-for-success" bash -c "cat /tmp/vscr-docker-from-docker.log | grep 'Success'"
check "log-contents" bash -c "cat /tmp/vscr-docker-from-docker.log | grep 'Proxying /var/run/docker-host.sock to /var/run/docker.sock for vscode'"

# Report result
reportResults