#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "gh-version" gh --version

check "gh-extension-installed" gh extension list | grep -q 'dlvhdr/gh-dash'
check "gh-extension-installed-2" gh extension list | grep -q 'github/gh-copilot'

# Report result
reportResults
