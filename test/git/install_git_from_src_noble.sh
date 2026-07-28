#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Import shared helper functions
source "$(dirname "$0")/utils.sh"

# Definition specific tests
check "version" git  --version
check "latest version" check_git_is_latest_version
check "gettext" dpkg-query -l gettext

cd /tmp && git clone https://github.com/devcontainers/feature-starter.git
cd feature-starter
check "perl" bash -c "git -c grep.patternType=perl grep -q 'a.+b'"

# Report result
reportResults

