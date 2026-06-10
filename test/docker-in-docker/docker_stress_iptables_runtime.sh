#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Stress scenario: validates the docker daemon works when the iptables
# alternative switching is deferred to container start (iptablesSwitchAtRuntime=true).
check "init-script-exists" bash -c "test -f /usr/local/share/docker-init.sh"
check "runtime-iptables-block-present" bash -c "grep -q 'update-alternatives --set iptables' /usr/local/share/docker-init.sh"

check "version" docker --version
check "docker-ps" bash -c "docker ps"
check "log-exists" bash -c "ls /tmp/dockerd.log"
check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"

# Report result
reportResults
