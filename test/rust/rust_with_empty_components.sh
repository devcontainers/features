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
check "correct rust version" rustup target list | grep aarch64-unknown-linux-gnu

# Check that no additional components are installed when empty list is provided
# Only the basic rust toolchain should be available
check "basic rust toolchain" rustc --version

# Verify that default components are automatically installed
check "rust-analyzer is installed" check_component_installed "rust-analyzer"
check "rust-src is installed" check_component_installed "rust-src"
check "rustfmt is installed" check_component_installed "rustfmt"
check "clippy is installed" check_component_installed "clippy"

# Report result
reportResults

