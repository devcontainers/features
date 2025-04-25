#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Function to check iptables version
iptablesCheck() {
    if command -v iptables > /dev/null 2>&1; then
        if iptables --version > /dev/null 2>&1; then
            echo "✔️ iptables is installed and functional."
        else
            echo "❌ iptables is installed but not functional."
        fi
    else
        echo "❌ iptables command not found."
    fi
}

# Function to check Fedora kernel version
kernelVersionCheck() {
    if uname -r > /dev/null 2>&1; then
        echo "✔️ Kernel version: $(uname -r)"
    else
        echo "❌ Unable to retrieve kernel version."
    fi
}

# Run checks
check "iptables version" iptablesCheck
check "kernel version" kernelVersionCheck

# Report results
reportResults