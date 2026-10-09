#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "distro" test "${ID}" = "mariner"
check "jq" jq  --version
check "bubblewrap" bwrap --version
check "util-linux" unshare --version
check "iptables" iptables --version

available_packages="$(sudo tdnf -q list)"
if grep -q '^slirp4netns\.' <<< "${available_packages}"; then
    check "slirp4netns" slirp4netns --version
else
    echo "Skipping slirp4netns: not available in the configured repositories."
fi

# Report result
reportResults