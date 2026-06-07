#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Default behavior (iptablesSwitchAtRuntime omitted -> false): switching happens
# at image build time, so docker-init.sh should NOT contain the runtime block.
check "init-script-exists" bash -c "test -f /usr/local/share/docker-init.sh"
check "no-runtime-iptables-block" bash -c "! grep -q 'update-alternatives --set iptables' /usr/local/share/docker-init.sh"

# The build-time switch should have set /etc/alternatives/iptables to one of the
# known backends. With the ip_tables module loaded on the host, legacy is preferred.
check "iptables-alternative-set" bash -c "readlink /etc/alternatives/iptables | grep -E 'iptables-(legacy|nft)$'"
check "iptables works" sudo iptables -L

check "version" docker --version
check "docker-ps" bash -c "docker ps"

# Report result
reportResults
