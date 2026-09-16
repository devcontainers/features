#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "gh-version" gh --version

check "gh-extension-installed" gh extension list | grep -q 'dlvhdr/gh-dash'
check "gh-extension-installed-2" gh extension list | grep -q 'github/gh-copilot'
check "gh-extension-installed-3" gh extension list | grep -q 'github/gh-aw'
check "gh-aw-runs" gh aw version
check "gh-extension-pinned-tag" grep -q 'tag: v0.88.8' "${XDG_DATA_HOME:-"${HOME}/.local/share"}/gh/extensions/gh-aw/manifest.yml"
check "gh-extension-pinned-flag" grep -q 'ispinned: true' "${XDG_DATA_HOME:-"${HOME}/.local/share"}/gh/extensions/gh-aw/manifest.yml"

# Report result
reportResults
