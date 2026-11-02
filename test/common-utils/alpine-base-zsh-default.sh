#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "alpine default shell zsh" \
  bash -c "getent passwd $(whoami) | awk -F : '{ print $7 }' | grep '/bin/zsh'"
check "bubblewrap" bwrap --version
check "slirp4netns" slirp4netns --version
check "util-linux" unshare --version
check "iptables" iptables --version

# Report result
reportResults
