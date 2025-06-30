#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Helper function to check component is installed
check_component_installed() {
    local component=$1
    if rustup component list | grep -q "${component}.*installed"; then
        return 0  # Component is installed (success)
    else
        return 1  # Component is not installed (failure)
    fi
}

# Helper function to check component is NOT installed
check_component_not_installed() {
    local component=$1
    if rustup component list | grep -q "${component}.*installed"; then
        return 1  # Component is installed (failure)
    else
        return 0  # Component is not installed (success)
    fi
}

# Definition specific tests
check "cargo version" cargo --version
check "rustc version" rustc --version

# Check that only specified minimal components are installed
check "rust-analyzer is installed" check_component_installed "rust-analyzer"
check "rust-src is installed" check_component_installed "rust-src"

# Check that other default components are NOT installed
check "rustfmt not installed" check_component_not_installed "rustfmt"
check "clippy not installed" check_component_not_installed "clippy"

# Report result
reportResults

