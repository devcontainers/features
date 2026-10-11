#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Load Linux distribution info
. /etc/os-release

# Check if the current user is root
check "root user" test "$(whoami)" = "root"

# Check if the Linux distro is Azure Linux
check "azurelinux distro" test "$ID" = "azurelinux"

# Definition specific tests
check "curl" curl --version
check "jq" jq  --version
check "bubblewrap" bwrap --version
check "util-linux" unshare --version
check "iptables" iptables --version

available_packages="$(tdnf -q list)"
if grep -q '^slirp4netns\.' <<< "${available_packages}"; then
    check "slirp4netns" slirp4netns --version
else
    echo "Skipping slirp4netns: not available in the configured repositories."
fi

# Report result
reportResults
