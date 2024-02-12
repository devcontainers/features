#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

echo "contents cat /tmp/vscr-docker-from-docker.log"
cat cat /tmp/vscr-docker-from-docker.log

check "docker buildx" bash -c "docker buildx version"
check "docker compose" bash -c "docker compose version"
check "docker-compose" bash -c "docker-compose --version"

check "docker-init-exists" bash -c "ls /usr/local/share/docker-init.sh"
check "log-exists" bash -c "ls /tmp/vscr-docker-from-docker.log"
check "log-contents-for-success" bash -c "cat /tmp/vscr-docker-from-docker.log | grep 'Success'"

sleep 5s
echo "contents cat /tmp/vscr-docker-from-docker.log"
cat cat /tmp/vscr-docker-from-docker.log

check "log-contents" bash -c "cat /tmp/vscr-docker-from-docker.log | grep 'Proxying /var/run/docker-host.sock to /var/run/docker.sock for vscode'"
check "docker-ps" bash -c "docker ps >/dev/null"

# Report result
reportResults