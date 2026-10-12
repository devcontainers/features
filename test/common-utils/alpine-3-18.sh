#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
. /etc/os-release
check "non-root user" test "$(whoami)" = "devcontainer"
check "distro" test "${ID}" = "alpine"
check "bashrc" ls /etc/bash/bashrc
check "libssl1.1 is installed" grep "libssl1.1" <(apk list --no-cache libssl1.1)
check "bubblewrap" bwrap --version
check "slirp4netns" slirp4netns --version
check "util-linux" unshare --version
check "iptables" iptables --version

# Report result
reportResults