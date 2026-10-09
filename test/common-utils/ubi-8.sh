#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "distro" test "${PLATFORM_ID}" = "platform:el8"
check "curl" curl --version
check "jq" jq  --version
check "slirp4netns" slirp4netns --version
check "util-linux" unshare --version
check "iptables" iptables --version

available_packages="$(sudo dnf -q list)"
if grep -q '^bubblewrap\.' <<< "${available_packages}"; then
    check "bubblewrap" bwrap --version
else
    echo "Skipping bubblewrap: not available in the configured repositories."
fi

# Report result
reportResults
