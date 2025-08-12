#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature specific tests
check "iptables works" sudo iptables -L
check "iptables uses legacy" bash -c "iptables --version | grep legacy"

check "version" docker  --version
check "docker-ps" bash -c "docker ps"
check "log-exists" bash -c "ls /tmp/dockerd.log"
check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"

# Report result
reportResults