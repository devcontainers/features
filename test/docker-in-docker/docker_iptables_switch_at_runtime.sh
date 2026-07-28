#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# iptablesSwitchAtRuntime=true: switching is deferred to container start, so the
# runtime block MUST have been written into docker-init.sh by install.sh.
check "init-script-exists" bash -c "test -f /usr/local/share/docker-init.sh"
check "runtime-iptables-block-present" bash -c "grep -q 'update-alternatives --set iptables' /usr/local/share/docker-init.sh"
check "runtime-iptables-block-has-legacy-branch" bash -c "grep -q '/usr/sbin/iptables-legacy' /usr/local/share/docker-init.sh"
check "runtime-iptables-block-has-nft-branch" bash -c "grep -q '/usr/sbin/iptables-nft' /usr/local/share/docker-init.sh"

# The runtime block runs as part of docker-init.sh (the feature's entrypoint),
# so by the time these tests execute the alternative must already be set.
check "iptables-alternative-set" bash -c "readlink /etc/alternatives/iptables | grep -E 'iptables-(legacy|nft)$'"
check "iptables works" sudo iptables -L

check "version" docker --version
check "docker-ps" bash -c "docker ps"

# Report result
reportResults
