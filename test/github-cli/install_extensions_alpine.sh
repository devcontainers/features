#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "gh-version" gh --version

# Extensions are installed for the non-root user on this image (uid 1000), by way of
# BusyBox `su`, which does not accept the util-linux options the Debian installer uses
check "gh-extension-installed" bash -c "gh extension list | grep -q 'dlvhdr/gh-dash'"
check "gh-extension-installed-2" bash -c "gh extension list | grep -q 'github/gh-copilot'"

# bash is not in the Alpine base image and is pulled in only to run the extensions script
check "bash-available" bash -c "command -v bash"

# Report result
reportResults
