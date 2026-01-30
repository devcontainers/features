#!/bin/bash
# Test script to detect Docker type

if [ -S "/var/run/docker.sock" ]; then
    echo "Root Docker detected"
    export DOCKER_HOST="unix:///var/run/docker-host.sock"
elif [ -S "/var/run/docker-rootless.sock" ]; then
    echo "Rootless Docker detected"  
    export DOCKER_HOST="unix:///var/run/docker-rootless.sock"
else
    echo "No Docker socket found"
    exit 1
fi

docker --version
docker info --format '{{.SecurityOptions}}'