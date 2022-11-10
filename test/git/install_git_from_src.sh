#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "source-dir" bash -c "which git | grep /usr/bin/git"
check "version" git  --version
check "gettext" dpkg-query -l gettext

# Report result
reportResults
