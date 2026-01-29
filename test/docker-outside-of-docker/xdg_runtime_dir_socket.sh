#!/bin/bash
set -e

source dev-container-features-test-lib

echo "=== XDG Runtime Directory Socket Test ==="

# Test XDG_RUNTIME_DIR style socket configuration
EXPECTED_SOCKET="/var/run/user-docker.sock"

# Check if the socket exists and is accessible
check "xdg-socket-exists" test -S "$EXPECTED_SOCKET"
check "xdg-socket-readable" test -r "$EXPECTED_SOCKET"

# Verify Docker functionality using the XDG-style socket
export DOCKER_HOST="unix://$EXPECTED_SOCKET"
check "docker-functional-xdg" docker ps >/dev/null

# Test that this works for rootless-style configurations
check "docker-version-xdg" docker version --format '{{.Client.Version}}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' >/dev/null

# Verify the socket path matches what a customer would configure
echo "XDG-style socket path: $EXPECTED_SOCKET"
echo "Docker host: $DOCKER_HOST"

reportResults