#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Define the function under test (matches src/copilot-cli/install.sh)
resolve_prerelease_version() {
    local repo_url="${1:?resolve_prerelease_version requires a repository URL}"
    git ls-remote --tags "${repo_url}" \
      | awk '{print $2}' | sed 's|refs/tags/||' \
      | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+(-[0-9]+)?$' \
      | sort -V | tail -n1
}

# Create a mock git script that returns controlled output
MOCK_DIR="$(mktemp -d)"
cat > "${MOCK_DIR}/git" << 'SCRIPT'
#!/bin/bash
# Return mock ls-remote output based on the repo URL argument
repo="${*: -1}"
case "${repo}" in
  "mock://basic")
    printf 'abc1234\trefs/tags/v1.0.1\ndef5678\trefs/tags/v1.0.9\nghi9012\trefs/tags/v1.0.10\njkl3456\trefs/tags/v1.0.45\nmno7890\trefs/tags/v1.0.2\n'
    ;;
  "mock://prerelease")
    printf 'abc1234\trefs/tags/v1.0.44\ndef5678\trefs/tags/v1.0.45-1\nghi9012\trefs/tags/v1.0.45-10\njkl3456\trefs/tags/v1.0.45-2\nmno7890\trefs/tags/v1.0.45\n'
    ;;
  "mock://stray")
    printf 'abc1234\trefs/tags/latest\ndef5678\trefs/tags/v1.0.3\nghi9012\trefs/tags/nightly\njkl3456\trefs/tags/v1.0.20\n'
    ;;
esac
SCRIPT
chmod +x "${MOCK_DIR}/git"
export PATH="${MOCK_DIR}:${PATH}"

# Test: version sort picks v1.0.45, not v1.0.9
result="$(resolve_prerelease_version "mock://basic")"
check "picks highest version (v1.0.45)" bash -c "[ '${result}' = 'v1.0.45' ]"

# Test: prerelease numeric suffixes sort correctly
result2="$(resolve_prerelease_version "mock://prerelease")"
check "picks highest prerelease (v1.0.45-10)" bash -c "[ '${result2}' = 'v1.0.45-10' ]"

# Test: filters out non-version tags
result3="$(resolve_prerelease_version "mock://stray")"
check "ignores non-version tags" bash -c "[ '${result3}' = 'v1.0.20' ]"

# Cleanup
rm -rf "${MOCK_DIR}"

# Report result
reportResults
