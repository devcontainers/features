#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" git --version
check "gettext" dpkg-query -l gettext

cd /tmp && git clone https://github.com/devcontainers/feature-starter.git
cd feature-starter

check "git-location" bash -c "which git | grep /usr/local/bin/git"

check "set-git-config-user-name" bash -c "git config --system user.name devcontainers"
check "gitconfig-file-location" bash -c "ls /etc/gitconfig"
check "gitconfig-contains-name" bash -c "cat /etc/gitconfig | grep 'name = devcontainers'"

check "usr-local-etc-config-does-not-exist" test ! -f "/usr/local/etc/gitconfig"

# Report result
reportResults
