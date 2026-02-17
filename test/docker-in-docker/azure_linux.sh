#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib

# OS identification (optional, can fail gracefully)
check "azure os detection" bash -c "cat /etc/os-release | grep -i azure || echo 'Not Azure Linux, but test can continue'"

# Core Docker functionality
check "docker version" docker --version
check "docker daemon running" docker info

# Docker init script (if using docker-in-docker feature)
check "docker init script exists" test -f "/usr/local/share/docker-init.sh"

# Basic functionality test
check "docker container test" docker run --rm alpine echo "test successful"

# The main Azure Linux specific test - DNS flag should NOT be present
check "dns flag should not be present" test ! "$(ps -ax | grep -v grep | grep -E 'dockerd.+\-\-dns')"

# Report result
reportResults