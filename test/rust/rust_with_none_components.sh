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

# When components is set to "none", none of the default components should be installed
check "rust-analyzer not installed" check_component_not_installed "rust-analyzer"
check "rust-src not installed" check_component_not_installed "rust-src"
check "rustfmt not installed" check_component_not_installed "rustfmt"
check "clippy not installed" check_component_not_installed "clippy"

# Report result
reportResults
