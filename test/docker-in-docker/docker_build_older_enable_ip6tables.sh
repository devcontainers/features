#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "docker-buildx" docker buildx version
check "docker-build" docker build ./
check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"
ip6tablesCheck() {
    if command -v ip6tables > /dev/null 2>&1; then
        if ip6tables -L > /dev/null 2>&1; then
            echo "✔️ ip6tables is enabled."
        else
            echo "❌ ip6tables is disabled."
        fi
    else
        echo "❕ip6tables command not found. ❕"
    fi
}

check "ip6tables" ip6tablesCheck

# Report result
reportResults