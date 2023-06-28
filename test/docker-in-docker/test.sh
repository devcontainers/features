#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature specific tests
check "version" docker  --version
check "docker-init-exists" bash -c "ls /usr/local/share/docker-init.sh"
check "log-exists" bash -c "ls /tmp/dockerd.log"

echo "(*) Printing dockerd log..."
echo ""
cat /tmp/dockerd.log
echo ""
echo ""

check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"
check "docker-ps" bash -c "docker ps"
check "run hello-world" bash -c "docker run hello-world"
check "validate hello-world image exists" bash -c "docker images | grep hello-world"

# Report result
reportResults