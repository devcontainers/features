#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" git  --version
check "gettext" dpkg-query -l gettext

cd /tmp && git clone https://github.com/devcontainers/feature-starter.git
cd feature-starter
check "perl" bash -c "git -c grep.patternType=perl grep -q 'a.+b'"

check "git-location" bash -c "which git | grep /usr/local/bin/git"

check "set-git-config-user-name" bash -c "git config --system user.name devcontainers"
check "gitconfig-file-location" bash -c "ls /usr/local/etc/gitconfig"
check "gitconfig-contains-name" bash -c "cat /usr/local/etc/gitconfig | grep 'name = devcontainers'"

check "linked-gitconfig-file-location" bash -c "ls /etc/gitconfig"
check "linked-gitconfig-contains-name" bash -c "cat /etc/gitconfig | grep 'name = devcontainers'"

# Report result
reportResults
