#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "version" gh --version

# The Alpine installer unpacks the release tarball rather than using a package, so `gh`
# should be on the PATH at the same location the Debian package would have put it
check "installed-to-usr-bin" bash -c "[ -x /usr/bin/gh ]"

# Nothing should have come from the community repository on this path
check "not-installed-by-apk" bash -c "! apk info --installed github-cli"

# Manual pages ship alongside the binary in the release tarball
check "man-page-installed" bash -c "[ -f /usr/share/man/man1/gh.1 ]"

# Report result
reportResults
