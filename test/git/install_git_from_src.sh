#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

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

# Definition specific tests
check "version" git  --version
check "version-is-latest" check_git_is_latest_version
check "gettext" dpkg-query -l gettext

cd /tmp && git clone https://github.com/devcontainers/feature-starter.git
cd feature-starter
check "perl" bash -c "git -c grep.patternType=perl grep -q 'a.+b'"

check "git-location" bash -c "which git | grep /usr/local/bin/git"

check "set-git-config-user-name" bash -c "git config --system user.name devcontainers"
check "gitconfig-file-location" bash -c "ls /etc/gitconfig"
check "gitconfig-contains-name" bash -c "cat /etc/gitconfig | grep 'name = devcontainers'"

check "usr-local-etc-config-does-not-exist" test ! -f "/usr/local/etc/gitconfig"

# Report result
reportResults
