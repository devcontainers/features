#!/usr/bin/env bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# End-to-end check that the "prerelease" channel actually resolves a tag and
# installs the binary. Regression guard for the inline pipeline in
# src/copilot-cli/install.sh.

check "copilot binary is on PATH" which copilot
check "copilot reports a version" bash -c "copilot -v"

# Auto-update flag file must exist for prerelease channel.
check "auto-update flag created for prerelease" test -f /etc/devcontainer-copilot-cli/auto-update

# Report result
reportResults
