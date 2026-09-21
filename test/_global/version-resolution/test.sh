#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${ROOT_DIR}/scripts/version-resolution.sh"
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cases.sh"

bash "${ROOT_DIR}/scripts/sync-version-resolution.sh" --check

network_calls=0
git() {
    network_calls=$((network_calls + 1))
    return 1
}

# shellcheck disable=SC2329
fallback_versions() {
    printf '%s\n' "1.4.2" "1.3.9"
}

curl() {
    printf '[{"name":"%s"}]\n' "${FAKE_FALLBACK_TAG:-v2.3.4}"
}

VERSION="1.2.3"
find_version_from_git_tags VERSION https://github.com/example/tool
if [ "${VERSION}" != "1.2.3" ] || [ "${network_calls}" -ne 0 ]; then
    echo "Exact versions must not perform remote resolution." >&2
    exit 1
fi

git() {
    printf '%s\n' \
        'abc refs/tags/v3.1.0' \
        'def refs/tags/v3.2.1'
}
VERSION="3.2"
find_version_from_git_tags VERSION https://github.com/example/tool >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "3.2.1" ] || grep -q "Trying" /tmp/version-resolution-output.log; then
    echo "Primary git tag resolution did not select the requested version line." >&2
    exit 1
fi

git() {
    network_calls=$((network_calls + 1))
    return 1
}

VERSION="latest"
find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 'example releases API' fallback_versions 1.2.3 >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.4.2" ]; then
    echo "Fallback resolver did not select the latest version." >&2
    exit 1
fi
if ! grep -q "Trying example releases API" /tmp/version-resolution-output.log; then
    echo "Fallback warning did not identify the alternate source." >&2
    exit 1
fi

fallback_versions() {
    return 1
}
VERSION="1.2"
find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 'example releases API' fallback_versions 1.2.3 >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.2.3" ] || ! grep -q "known-good version 1.2.3" /tmp/version-resolution-output.log; then
    echo "Compatible known-good fallback was not selected or reported." >&2
    exit 1
fi

VERSION="2.0"
if find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 'example releases API' fallback_versions 1.2.3 >/tmp/version-resolution-error.log 2>&1; then
    echo "An incompatible known-good version must be rejected." >&2
    exit 1
fi
if ! grep -q "Specify an exact version" /tmp/version-resolution-error.log; then
    echo "Final resolution error is not actionable." >&2
    exit 1
fi

fallback_versions() {
    printf '%s\n' "not-a-version" "release-next"
}
VERSION="latest"
if find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 'malformed source' fallback_versions '' >/tmp/version-resolution-error.log 2>&1; then
    echo "Malformed fallback versions must be rejected." >&2
    exit 1
fi

VERSION="latest"
find_version_from_git_tags VERSION https://github.com/example/unpinned >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "2.3.4" ] || ! grep -q "GitHub REST API" /tmp/version-resolution-output.log; then
    echo "Automatic GitHub REST fallback did not select and report a version." >&2
    exit 1
fi

for test_case in "${VERSION_RESOLUTION_CASES[@]}"; do
    IFS='|' read -r feature label repository prefix last_part_optional suffix_regex request fallback_tag expected <<< "${test_case}"
    # shellcheck disable=SC1090
    source "${ROOT_DIR}/src/${feature}/scripts/version-resolution.sh"
    VERSION="${expected}"
    rm -f /tmp/version-resolution-network-call
    git() {
        touch /tmp/version-resolution-network-call
        return 1
    }
    find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" >/tmp/version-resolution-output.log 2>&1
    if [ -e /tmp/version-resolution-network-call ]; then
        echo "${feature} ${label}: exact version performed remote resolution." >&2
        exit 1
    fi

    git() {
        return 1
    }
    FAKE_FALLBACK_TAG="${fallback_tag}"
    VERSION="${request}"
    if [ "${feature}" = "go" ]; then
        go_fallback_versions() {
            printf '%s\n' "${FAKE_FALLBACK_TAG}"
        }
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "the official Go release index" go_fallback_versions "${expected}" >/tmp/version-resolution-output.log 2>&1
    else
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" >/tmp/version-resolution-output.log 2>&1
    fi
    if [ "${VERSION}" != "${expected}" ]; then
        echo "${feature} ${label}: expected ${expected}, got ${VERSION}." >&2
        exit 1
    fi
    if ! grep -qE 'Trying (GitHub REST API|the official Go release index)' /tmp/version-resolution-output.log; then
        echo "${feature} ${label}: fallback warning did not identify its source." >&2
        exit 1
    fi
done

echo "Version resolution tests passed."