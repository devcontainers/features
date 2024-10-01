#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

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
check "ip6tables check" bash -c "docker network inspect bridge"
check "docker-build" docker build ./

reportResults