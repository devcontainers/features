#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" git  --version
check "gettext" dpkg-query -l gettext

# Report result
reportResults
