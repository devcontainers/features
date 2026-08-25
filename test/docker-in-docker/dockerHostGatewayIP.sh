#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "host gateway ip setting set" ps -ax | grep -v grep | grep -E "dockerd.+--host-gateway-ip 192.168.0.1"

# Report result
reportResults
