#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

check "gh-version" gh --version
check "github-cli-auth-script-installed" test -x /usr/local/share/github-cli-auth-on-setup.sh
check "github-cli-auth-hook-installed" bash -lc "grep -Fq 'bash /usr/local/share/github-cli-auth-on-setup.sh' /etc/bash.bashrc"
check "github-cli-auth-with-token" /bin/bash "$(dirname "$0")/verify_auth_with_token.sh"

# Report result
reportResults
