#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check_info() {
    local info=$1
    check "devcontainer-info ${info}" sh -c "devcontainer-info | grep test-${info}"
}

# Definition specific tests
check "user" bash -c "whoami | grep vscode"
check_info "version"
check_info "id"
check_info "variant"
check_info "repository"
check_info "release"
check_info "revision"
check_info "time"
check_info "url"

# Check if the sudoers file for the non-root user exists
check "sudoers file exists" test -f /etc/sudoers.d/$(whoami)

# Check if the sudoers entry for the non-root user is correctly configured
check "sudoers entry for non-root user" sudo grep "$(whoami) ALL=(root) NOPASSWD:ALL" /etc/sudoers.d/$(whoami)

# Report result
reportResults
