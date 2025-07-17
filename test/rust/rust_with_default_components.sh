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

# Definition specific tests
check "cargo version" cargo --version
check "rustc version" rustc --version
check "correct rust version" rustup target list | grep aarch64-unknown-linux-gnu

# Check that default components are installed
check "rust-analyzer is installed" check_component_installed "rust-analyzer"
check "rust-src is installed" check_component_installed "rust-src"
check "rustfmt is installed" check_component_installed "rustfmt"
check "clippy is installed" check_component_installed "clippy"

# Report result
reportResults

