#!/bin/bash
set -e

source dev-container-features-test-lib

echo "=== Rootless Docker Socket Configuration Test ==="

# Test the custom rootless socket path
EXPECTED_SOCKET="/var/run/docker-rootless.sock"

# Check if the configured rootless socket exists and is accessible
check "rootless-socket-exists" test -S "$EXPECTED_SOCKET"
check "rootless-socket-readable" test -r "$EXPECTED_SOCKET"

# Verify Docker functionality using the rootless socket
export DOCKER_HOST="unix://$EXPECTED_SOCKET"
check "docker-functional-rootless" docker ps >/dev/null

# Test basic Docker operations with rootless configuration
check "docker-version-rootless" docker version --format '{{.Client.Version}}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' >/dev/null
check "docker-info-rootless" docker info >/dev/null

# Demonstrate that customers can configure custom socket paths
echo "Configured rootless socket path: $EXPECTED_SOCKET"
echo "Docker host: $DOCKER_HOST"

reportResults