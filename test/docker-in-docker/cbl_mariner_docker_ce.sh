#!/bin/bash
# test script for cbl_mariner_docker_ce scenario (Moby = false)

set -e

echo "=== Testing cbl_mariner_docker_ce scenario (Docker CE) ==="

# Set environment variables for the scenario
export VERSION="latest"
export MOBY="false"
export AZUREDNSAUTODETECTION="false"

# Source OS info
. /etc/os-release
echo "OS: $ID $VERSION_ID"

# Check package manager
if type tdnf > /dev/null 2>&1; then
    echo "Using tdnf"
else
    echo "ERROR: tdnf not found"
    exit 1
fi

# Validate
if command -v docker > /dev/null 2>&1; then
    docker --version
    echo "SUCCESS: Docker installed"
else
    echo "ERROR: Docker not installed"
    exit 1
fi

echo "=== cbl_mariner_docker_ce test passed ==="