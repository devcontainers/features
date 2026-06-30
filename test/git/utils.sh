#!/bin/bash

# Shared helper functions for git "install from source" test scenarios.

# Resolves the latest stable git version from GitHub
get_latest_git_version() {
    curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/git/git/tags" \
        | grep -oP '"name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+(?=")' \
        | sort -rV \
        | head -n 1
}

# Verifies the installed git version matches the latest stable version on GitHub
check_git_is_latest_version() {
    local latest_version installed_version
    latest_version="$(get_latest_git_version)"
    installed_version="$(git --version | awk '{print $3}')"
    [ -n "$latest_version" ] && [ "$installed_version" = "$latest_version" ]
}
