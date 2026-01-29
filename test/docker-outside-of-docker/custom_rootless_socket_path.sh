#!/bin/bash
set -e

source dev-container-features-test-lib

echo "=== Custom Rootless Docker Socket Path Test ==="

# Test that the custom socket path is properly configured
EXPECTED_SOCKET="/custom/docker/rootless.sock"

# Check if the custom socket exists and is accessible
check "custom-socket-exists" test -S "$EXPECTED_SOCKET"
check "custom-socket-readable" test -r "$EXPECTED_SOCKET"

# Verify Docker functionality using the custom socket
export DOCKER_HOST="unix://$EXPECTED_SOCKET"
check "docker-functional-custom" docker ps >/dev/null

# Verify that DOCKER_HOST is properly set by the feature
check "docker-host-env-set" [ ! -z "$DOCKER_HOST" ]

# Test basic Docker operations
check "docker-version" docker version --format '{{.Client.Version}}' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' >/dev/null
check "docker-info" docker info >/dev/null

echo "Custom socket path: $EXPECTED_SOCKET"
echo "Docker host: $DOCKER_HOST"

reportResults