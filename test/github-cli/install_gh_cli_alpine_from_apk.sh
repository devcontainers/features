#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" gh --version

# This path installs from Alpine's community repository, so apk should own the package -
# which is what distinguishes it from the release-tarball path
check "installed-by-apk" bash -c "apk info --installed github-cli"

check "owned-binary" bash -c "apk info --contents github-cli | grep -qE '(^|/)usr/bin/gh$'"

# Report result
reportResults
