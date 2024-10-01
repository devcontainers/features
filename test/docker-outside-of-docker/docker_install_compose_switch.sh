#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Check if compose-switch is installed
check_compose_switch_installation() {
    COMPOSE_SWITCH_BINARY="/usr/local/bin/compose-switch"
    # Check if the binary exists
    if [ ! -x "$COMPOSE_SWITCH_BINARY" ]; then
        echo "compose-switch binary not found at $COMPOSE_SWITCH_BINARY"
        exit 1
    else 
        compose_switch_version=$("$COMPOSE_SWITCH_BINARY" --version | awk '{print $4}')
        if [ -z "$compose_switch_version" ]; then
            echo "Unable to determine compose-switch version"
        else
            echo "compose-switch version: $compose_switch_version"
            echo -e "\n✅ compose-switch is installed"
        fi
    fi
}

check "Check whether compose-switch is installed" check_compose_switch_installation

reportResults
 