#!/bin/bash
# Test script to assert root Docker socket usage

if [ ! -S "/var/run/docker-host.sock" ]; then
    echo "ERROR: Root Docker socket not found"
    exit 1
fi

echo "Root Docker detected"
export DOCKER_HOST="unix:///var/run/docker-host.sock"
docker --version