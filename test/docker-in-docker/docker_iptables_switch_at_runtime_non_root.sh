#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "entrypoint runs as codespace" bash -c "test \"$(id -un)\" = codespace"
check "iptables version" iptables --version
# The build-time switch should have set /etc/alternatives/iptables to one of the
# known backends. With the ip_tables module loaded on the host, legacy is preferred.
check "iptables-alternative-set" bash -c "readlink /etc/alternatives/iptables | grep -E 'iptables-(legacy|nft)$'"
check "iptables works" sudo iptables -L

# Report result
reportResults