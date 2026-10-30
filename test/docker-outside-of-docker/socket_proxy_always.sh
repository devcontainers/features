#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# This script runs in a fresh process, which always gets up-to-date supplementary groups, so it
# cannot show whether the container's own command (started before the entrypoint finished) can use
# the socket. Take that command's groups instead and run docker with exactly those.
INIT_PID="$(pgrep -u "$(id -u)" -f '[C]ontainer started' | head -n 1)"
INIT_GROUPS="$(awk '/^Groups:/ {$1=""; print}' "/proc/${INIT_PID}/status" | xargs | tr ' ' ',')"
DOCKER_BIN="$(command -v docker)"

echo "container command pid: ${INIT_PID}, its groups: ${INIT_GROUPS}"

check "container-command-found" bash -c "[ -n '${INIT_PID}' ]"
check "docker-socket-is-proxy" bash -c "[ -S /var/run/docker.sock ] && [ ! -L /var/run/docker.sock ]"
check "socat-proxy-running" bash -c "pgrep -af 'socat UNIX-LISTEN:/var/run/docker.sock.*UNIX-CONNECT:/var/run/docker-host.sock'"
check "log-contents-for-proxy" bash -c "grep 'Enabling socket proxy' /tmp/vscr-docker-from-docker.log"
check "docker-ps" bash -c "docker ps >/dev/null"
check "docker-ps-with-container-command-groups" bash -c "sudo setpriv --reuid '$(id -u)' --regid '$(id -g)' --groups '${INIT_GROUPS}' env HOME=/tmp '${DOCKER_BIN}' ps >/dev/null"

# Report result
reportResults
