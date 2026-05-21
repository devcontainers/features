#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Source the install script's resolve_prerelease_version function
# We extract it by sourcing, but we only need the function definition
eval "$(sed -n '/^resolve_prerelease_version()/,/^}/p' /usr/local/share/copilot-cli-install.sh 2>/dev/null || true)"

# If sourcing didn't work, define it inline (matches src/copilot-cli/install.sh)
if ! type resolve_prerelease_version &>/dev/null; then
    resolve_prerelease_version() {
        local repo_url="${1:-}"
        if [ -n "${repo_url}" ]; then
            git ls-remote --tags "${repo_url}"
        else
            cat
        fi | awk '{print $2}' | sed 's|refs/tags/||' \
          | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?$' \
          | sort -V | tail -n1
    }
fi

# Mock git ls-remote output (alphabetically v1.0.9 > v1.0.45)
MOCK_LS_REMOTE="abc1234\trefs/tags/v1.0.1
def5678\trefs/tags/v1.0.9
ghi9012\trefs/tags/v1.0.10
jkl3456\trefs/tags/v1.0.45
mno7890\trefs/tags/v1.0.2"

# Test: version sort picks v1.0.45, not v1.0.9
result="$(echo "${MOCK_LS_REMOTE}" | resolve_prerelease_version)"
check "picks highest version (v1.0.45)" bash -c "[ '${result}' = 'v1.0.45' ]"

# Test: prerelease numeric suffixes sort correctly
MOCK_PRERELEASE="abc1234\trefs/tags/v1.0.44
def5678\trefs/tags/v1.0.45-1
ghi9012\trefs/tags/v1.0.45-10
jkl3456\trefs/tags/v1.0.45-2
mno7890\trefs/tags/v1.0.45"

result2="$(echo "${MOCK_PRERELEASE}" | resolve_prerelease_version)"
check "picks highest prerelease (v1.0.45-10)" bash -c "[ '${result2}' = 'v1.0.45-10' ]"

# Test: filters out non-version tags
MOCK_STRAY="abc1234\trefs/tags/latest
def5678\trefs/tags/v1.0.3
ghi9012\trefs/tags/nightly
jkl3456\trefs/tags/v1.0.20"

result3="$(echo "${MOCK_STRAY}" | resolve_prerelease_version)"
check "ignores non-version tags" bash -c "[ '${result3}' = 'v1.0.20' ]"

# Report result
reportResults
