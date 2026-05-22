#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

resolve_prerelease_version() {
    local repo_versions="${1:?resolve_prerelease_version requires the copilot-cli repo tags as input}"
    printf '%s\n' "${repo_versions}" \
      | awk '{print $2}' | sed 's|refs/tags/||' \
      | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?$' \
      | sort -V | tail -n1
}

# Tests the tag-resolution pipeline used by src/copilot-cli/install.sh for the
# "prerelease" channel. 

check "copilot binary is on PATH" which copilot
check "copilot reports a version" bash -c "copilot -v"

result1="$(resolve_prerelease_version $'abc1234\trefs/tags/v1.0.1\ndef5678\trefs/tags/v1.0.9\nghi9012\trefs/tags/v1.0.10\njkl3456\trefs/tags/v1.0.45\nmno7890\trefs/tags/v1.0.2\n')"
check "picks highest version (v1.0.45)" bash -c "[ '${result1}' = 'v1.0.45' ]"

result2="$(resolve_prerelease_version $'abc1234\trefs/tags/v1.0.44\ndef5678\trefs/tags/v1.0.45-1\nghi9012\trefs/tags/v1.0.45-10\njkl3456\trefs/tags/v1.0.45-2\nmno7890\trefs/tags/v1.0.45\n')"
check "picks highest prerelease (v1.0.45-10)" bash -c "[ '${result2}' = 'v1.0.45-10' ]"

result3="$(resolve_prerelease_version $'abc1234\trefs/tags/latest\ndef5678\trefs/tags/v1.0.3\nghi9012\trefs/tags/nightly\njkl3456\trefs/tags/v1.0.20\n')"
check "picks highest version ignoring non-version tags (v1.0.20)" bash -c "[ '${result3}' = 'v1.0.20' ]"

# Report result
reportResults
