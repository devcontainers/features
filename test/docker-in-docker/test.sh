#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature specific tests
check "version" docker  --version
check "docker-init-exists" bash -c "ls /usr/local/share/docker-init.sh"
check "docker-ps" bash -c "docker ps"
check "log-exists" bash -c "ls /tmp/dockerd.log"
check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"

# Report result
reportResults