#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Feature specific tests
check "docker-ps" bash -c "docker ps"
# Fail loudly if dockerd never finished initializing, printing the real error
check "dockerd-started-successfully" bash -c '
    if ! grep -q "Daemon has completed initialization" /tmp/dockerd.log; then
        echo "❌ Docker daemon failed to start. Last errors from /tmp/dockerd.log:"
        echo "----- dockerd.log (tail) -----"
        tail -n 100 /tmp/dockerd.log
        echo "----- error/fatal lines -----"
        grep -iE "error|fatal|failed|panic" /tmp/dockerd.log || true
        exit 1
    fi
'

check "iptables works" sudo iptables -L
check "iptables uses nf_tables" bash -c "iptables --version | grep nf_tables"

check "version" docker  --version
check "docker-ps" bash -c "docker ps"
check "log-exists" bash -c "ls /tmp/dockerd.log"
check "log-for-completion" bash -c "cat /tmp/dockerd.log | grep 'Daemon has completed initialization'"
check "log-contents" bash -c "cat /tmp/dockerd.log | grep 'API listen on /var/run/docker.sock'"

# Report result
reportResults

