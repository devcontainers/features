#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "gh-version" gh --version
check "github-cli-deferred-extension-config-installed" test -f /usr/local/share/github-cli/extensions.env
check "github-cli-deferred-extension-installer-installed" test -x /usr/local/share/github-cli/install-extensions.sh
check "github-cli-installs-extensions-with-gh-after-auth" /bin/bash "$(dirname "$0")/verify_extensions_install_after_auth.sh"

# Report result
reportResults