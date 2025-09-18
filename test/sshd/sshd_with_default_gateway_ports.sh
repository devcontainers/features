#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "correct default GatewayPorts" grep "GatewayPorts no" /etc/ssh/sshd_config

# Report result
reportResults