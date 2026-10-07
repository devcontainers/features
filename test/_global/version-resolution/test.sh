#!/usr/bin/env bash
# shellcheck disable=SC2317,SC2329
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${ROOT_DIR}/scripts/version-resolution.sh"
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/cases.sh"

bash "${ROOT_DIR}/scripts/sync-version-resolution.sh" --check

passed=0

pass() {
    passed=$((passed + 1))
    printf 'ok %d - %s\n' "${passed}" "$1"
}

fail() {
    printf 'not ok %d - %s\n' "$((passed + 1))" "$1" >&2
    if [ -s /tmp/version-resolution-output.log ]; then
        cat /tmp/version-resolution-output.log >&2
    fi
    exit 1
}

network_calls=0
git() {
    network_calls=$((network_calls + 1))
    return 1
}

fallback_versions() {
    printf '%s\n' "1.4.2" "1.3.9"
}

curl() {
    printf '[{"name":"%s"}]\n' "${FAKE_FALLBACK_TAG:-v2.3.4}"
}

VERSION="1.2.3"
find_version_from_git_tags VERSION https://github.com/example/tool
if [ "${VERSION}" != "1.2.3" ] || [ "${network_calls}" -ne 0 ]; then
    fail "exact versions avoid remote resolution"
fi
pass "exact versions avoid remote resolution"

git() {
    printf '%s\n' \
        'abc refs/tags/v3.1.0' \
        'def refs/tags/v3.2.1'
}
VERSION="3.2"
find_version_from_git_tags VERSION https://github.com/example/tool >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "3.2.1" ] || grep -q "Trying" /tmp/version-resolution-output.log; then
    fail "primary git tags select the requested version line"
fi
pass "primary git tags select the requested version line"

rm -f /tmp/version-resolution-network-call
git() {
    touch /tmp/version-resolution-network-call
    return 1
}
VERSION="v1.33.0"
find_version_from_git_tags VERSION https://github.com/kubernetes/kubernetes >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.33.0" ] || [ -e /tmp/version-resolution-network-call ]; then
    fail "prefixed exact versions normalize without remote resolution"
fi
pass "prefixed exact versions normalize without remote resolution"

git() {
    network_calls=$((network_calls + 1))
    return 1
}

VERSION="latest"
find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 1.2.3 'example releases API' fallback_versions >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.4.2" ]; then
    fail "alternate resolver selects the latest version"
fi
if ! grep -q "Trying example releases API" /tmp/version-resolution-output.log; then
    fail "alternate resolver warning identifies its source"
fi
pass "alternate resolver selects the latest version and reports its source"

fallback_versions() {
    return 1
}
VERSION="1.2"
find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 1.2.3 'example releases API' fallback_versions >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.2.3" ] || ! grep -q "known-good version 1.2.3" /tmp/version-resolution-output.log; then
    fail "compatible known-good fallback is selected and reported"
fi
pass "compatible known-good fallback is selected and reported"

VERSION="2.0"
if find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' 1.2.3 'example releases API' fallback_versions >/tmp/version-resolution-error.log 2>&1; then
    fail "incompatible known-good versions are rejected"
fi
if ! grep -q "Specify an exact version" /tmp/version-resolution-error.log; then
    fail "final resolution error is actionable"
fi
pass "incompatible known-good versions are rejected with actionable errors"

fallback_versions() {
    printf '%s\n' "not-a-version" "release-next"
}
VERSION="latest"
if find_version_from_git_tags VERSION https://github.com/example/tool tags/v . false '' '' 'malformed source' fallback_versions >/tmp/version-resolution-error.log 2>&1; then
    fail "malformed fallback versions are rejected"
fi
pass "malformed fallback versions are rejected"

VERSION="latest"
find_version_from_git_tags VERSION https://github.com/example/unpinned >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "2.3.4" ] || ! grep -q "GitHub REST API" /tmp/version-resolution-output.log; then
    fail "automatic GitHub REST fallback selects and reports a version"
fi
pass "automatic GitHub REST fallback selects and reports a version"

required_features=(
    copilot-cli
    docker-in-docker
    docker-outside-of-docker
    git-lfs
    github-cli
    go
    kubectl-helm-minikube
    nix
    node
    php
    powershell
    python
    rust
    terraform
)
declare -A covered_features=()
for test_case in "${VERSION_RESOLUTION_CASES[@]}"; do
    IFS='|' read -r feature _ <<< "${test_case}"
    covered_features["${feature}"]=true
done
for feature in "${required_features[@]}"; do
    if [ "${covered_features[${feature}]:-false}" != "true" ]; then
        fail "fallback matrix covers ${feature}"
    fi
done
pass "fallback matrix covers all ${#required_features[@]} required features"

for test_case in "${VERSION_RESOLUTION_CASES[@]}"; do
    IFS='|' read -r feature label known_good_variable repository prefix last_part_optional suffix_regex request <<< "${test_case}"
    installer="${ROOT_DIR}/src/${feature}/install.sh"
    expected="$(sed -n "s/^${known_good_variable}=\"\(.*\)\"$/\1/p" "${installer}")"
    if [ -z "${expected}" ]; then
        fail "${feature}/${label}: ${known_good_variable} is declared at the top level"
    fi
    if ! grep 'find_version_from_git_tags' "${installer}" | grep -Fq "\${${known_good_variable}}"; then
        fail "${feature}/${label}: resolver uses ${known_good_variable}"
    fi
    pass "${feature}/${label}: installer wires ${known_good_variable}"

    tag_prefix=${prefix#refs/}
    tag_prefix=${tag_prefix#tags/}
    fallback_tag="${tag_prefix}${expected}"
    VERSION="${expected}"
    rm -f /tmp/version-resolution-network-call
    git() {
        touch /tmp/version-resolution-network-call
        return 1
    }
    find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "${expected}" >/tmp/version-resolution-output.log 2>&1
    if [ -e /tmp/version-resolution-network-call ]; then
        fail "${feature}/${label}: exact version avoids remote resolution"
    fi
    pass "${feature}/${label}: exact version avoids remote resolution"

    git() {
        return 1
    }
    FAKE_FALLBACK_TAG="${fallback_tag}"
    VERSION="${request}"
    if [ "${feature}" = "go" ]; then
        go_fallback_versions() {
            printf '%s\n' "${expected}"
        }
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "${expected}" "the official Go release index" go_fallback_versions >/tmp/version-resolution-output.log 2>&1
    else
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "${expected}" >/tmp/version-resolution-output.log 2>&1
    fi
    if [ "${VERSION}" != "${expected}" ]; then
        fail "${feature}/${label}: alternate source selects ${expected}"
    fi
    if ! grep -qE 'Trying (GitHub REST API|the official Go release index)' /tmp/version-resolution-output.log; then
        fail "${feature}/${label}: alternate-source warning identifies its source"
    fi
    pass "${feature}/${label}: alternate source selects ${expected} and is reported"

    git() {
        return 1
    }
    curl() {
        return 1
    }
    fallback_unavailable() {
        return 1
    }
    VERSION="${request}"
    if [ "${feature}" = "go" ]; then
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "${expected}" "the official Go release index" fallback_unavailable >/tmp/version-resolution-output.log 2>&1
    elif [ "${feature}" = "powershell" ] && [ "${label}" = "preview" ]; then
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "${expected}" "GitHub REST API" fallback_unavailable >/tmp/version-resolution-output.log 2>&1
    else
        find_version_from_git_tags VERSION "${repository}" "${prefix}" . "${last_part_optional}" "${suffix_regex}" "${expected}" >/tmp/version-resolution-output.log 2>&1
    fi
    if [ "${VERSION}" != "${expected}" ] || ! grep -q "known-good version ${expected}" /tmp/version-resolution-output.log; then
        fail "${feature}/${label}: unavailable alternate source selects known-good ${expected}"
    fi
    pass "${feature}/${label}: unavailable alternate source selects known-good ${expected}"

    curl() {
        printf '[{"name":"%s"}]\n' "${FAKE_FALLBACK_TAG:-v2.3.4}"
    }
done

printf '1..%d\n' "${passed}"
printf 'Version resolution tests passed: %d assertions.\n' "${passed}"