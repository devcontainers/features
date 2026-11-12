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

for request in 1x2x3 1.2x3 1x2.3; do
    VERSION="${request}"
    if find_version_from_git_tags VERSION https://github.com/example/tool >/tmp/version-resolution-output.log 2>&1; then
        fail "malformed exact version ${request} is rejected"
    fi
    pass "malformed exact version ${request} is rejected"
done

git() {
    printf '%s\n' 'abc refs/tags/v9x9x9' 'def refs/tags/v1.2.3'
}
VERSION="latest"
find_version_from_git_tags VERSION https://github.com/example/tool >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.2.3" ]; then
    fail "git candidates require literal version separators"
fi
pass "git candidates require literal version separators"

git() {
    return 1
}
curl() {
    printf '%s\n' '[{"name":"v9x9x9"},{"name":"v1.2.3"}]'
}
VERSION="latest"
find_version_from_git_tags VERSION https://github.com/example/tool >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.2.3" ]; then
    fail "REST candidates require literal version separators"
fi
pass "REST candidates require literal version separators"
curl() {
    printf '[{"name":"%s"}]\n' "${FAKE_FALLBACK_TAG:-v2.3.4}"
}

git() {
    printf '%s\n' \
        'abc refs/tags/go1.20' \
        'def refs/tags/go1.23.12' \
        'ghi refs/tags/go1.24.0' \
        'jkl refs/tags/go1.24.9' \
        'mno refs/tags/go1.25.0'
}
for test_case in '1.24|1.24.9' 'go1.24|1.24.9' '1.23|1.23.12' '1.20|1.20'; do
    IFS='|' read -r request expected <<< "${test_case}"
    VERSION="${request}"
    find_version_from_git_tags VERSION https://go.googlesource.com/go tags/go . true >/tmp/version-resolution-output.log 2>&1
    if [ "${VERSION}" != "${expected}" ]; then
        fail "Go request ${request} resolves to ${expected}"
    fi
    pass "Go request ${request} resolves to ${expected}"
done

rm -f /tmp/version-resolution-network-call
git() {
    touch /tmp/version-resolution-network-call
    return 1
}
VERSION="go1.24.9"
find_version_from_git_tags VERSION https://go.googlesource.com/go tags/go . true >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.24.9" ] || [ -e /tmp/version-resolution-network-call ]; then
    fail "exact Go versions avoid remote resolution with optional patches enabled"
fi
pass "exact Go versions avoid remote resolution with optional patches enabled"

go_partial_versions() {
    printf '%s\n' "1.24.0" "1.24.9" "1.25.0"
}
VERSION="1.24"
find_version_from_git_tags VERSION https://go.googlesource.com/go tags/go . true '' '' 'the official Go release index' go_partial_versions >/tmp/version-resolution-output.log 2>&1
if [ "${VERSION}" != "1.24.9" ]; then
    fail "partial Go versions resolve through the alternate source"
fi
pass "partial Go versions resolve through the alternate source"

for scenario in standalone-latest standalone-partial standalone-invalid bundled-rest bundled-pinned; do
    if ! (
        temporary_dir="$(mktemp -d)"
        trap 'rm -rf "${temporary_dir}"' EXIT
        NVM_VERSION="latest"
        expected="0.40.9"
        git() {
            printf '%s\n' 'abc refs/tags/v0.39.7' 'def refs/tags/v0.40.9'
        }
        curl() {
            echo "Unexpected REST request from standalone installer" >&2
            return 1
        }
        case "${scenario}" in
            standalone-partial)
                NVM_VERSION="0.39"
                expected="0.39.7"
                ;;
            standalone-invalid)
                NVM_VERSION="99"
                ;;
            bundled-*)
                mkdir -p "${temporary_dir}/scripts"
                cp "${ROOT_DIR}/src/node/scripts/version-resolution.sh" "${temporary_dir}/scripts/"
                git() { return 1; }
                if [ "${scenario}" = "bundled-rest" ]; then
                    curl() { printf '%s\n' '[{"name":"v0.40.9"}]'; }
                else
                    curl() { return 1; }
                    expected="$(sed -n 's/^NVM_LAST_KNOWN_VERSION="\(.*\)"$/\1/p' "${ROOT_DIR}/src/node/install.sh")"
                fi
                ;;
        esac
        export NVM_VERSION
        export -f git curl
        {
            printf '%s\n' 'set -e'
            sed -n '/^NVM_LAST_KNOWN_VERSION=/p' "${ROOT_DIR}/src/node/install.sh"
            sed -n '/^find_version_from_git_tags() {/,/^}/p' "${ROOT_DIR}/src/node/install.sh"
            sed -n '/^if ! type git >/,/^# Adjust node version/p' "${ROOT_DIR}/src/node/install.sh"
            sed -n '/^find_version_from_git_tags NVM_VERSION /p' "${ROOT_DIR}/src/node/install.sh"
        } > "${temporary_dir}/install.sh"
        if bash "${temporary_dir}/install.sh" > "${temporary_dir}/output.log" 2>&1; then
            if [ "${scenario}" = "standalone-invalid" ] || ! grep -qx "NVM_VERSION=${expected}" "${temporary_dir}/output.log"; then
                cat "${temporary_dir}/output.log" >&2
                exit 1
            fi
        elif [ "${scenario}" != "standalone-invalid" ] || ! grep -q "Invalid NVM_VERSION value: 99" "${temporary_dir}/output.log"; then
            cat "${temporary_dir}/output.log" >&2
            exit 1
        fi
    ) >/tmp/version-resolution-output.log 2>&1; then
        fail "Node installer version resolution: ${scenario}"
    fi
    pass "Node installer version resolution: ${scenario}"
done

for scenario in stable mixed numeric-suffix rest pinned; do
    if ! (
        # Load the installer function without running package installation or downloads.
        # shellcheck disable=SC1090
        source <(sed -n '/^install_using_github() {/,/^}/p' "${ROOT_DIR}/src/copilot-cli/install.sh")
        COPILOT_CLI_LAST_KNOWN_VERSION="$(sed -n 's/^COPILOT_CLI_LAST_KNOWN_VERSION="\(.*\)"$/\1/p' "${ROOT_DIR}/src/copilot-cli/install.sh")"
        CLI_VERSION="prerelease"
        curl_installed=false
        downloaded_url=""
        git_tags=""
        rest_tag=""
        expected="1.0.100"
        case "${scenario}" in
            stable) git_tags='abc refs/tags/v1.0.100' ;;
            mixed) git_tags=$'abc refs/tags/v1.0.99-0\ndef refs/tags/v1.0.100' ;;
            numeric-suffix)
                git_tags=$'abc refs/tags/v1.0.45\ndef refs/tags/v1.0.45-2\nghi refs/tags/v1.0.45-10'
                expected="1.0.45-10"
                ;;
            rest) rest_tag="v1.0.100" ;;
            pinned) expected="${COPILOT_CLI_LAST_KNOWN_VERSION}" ;;
        esac
        check_packages() {
            if [[ " $* " == *" curl "* ]]; then
                curl_installed=true
            fi
        }
        dpkg() {
            printf '%s\n' amd64
        }
        git() {
            [ -n "${git_tags}" ] || return 1
            printf '%s\n' "${git_tags}"
        }
        curl() {
            if [ "${curl_installed}" != "true" ]; then
                echo "curl was not installed before REST resolution" >&2
                return 127
            fi
            [ -n "${rest_tag}" ] || return 1
            printf '[{"name":"%s"}]\n' "${rest_tag}"
        }
        download_from_github() {
            downloaded_url=$1
        }
        install_using_github || exit 1
        if [ "${curl_installed}" != "true" ] || [ "${CLI_VERSION}" != "${expected}" ] || [ "${downloaded_url}" != "https://github.com/github/copilot-cli/releases/download/v${expected}/copilot-linux-x64.tar.gz" ]; then
            echo "Unexpected Copilot download: ${downloaded_url}; curl installed: ${curl_installed}" >&2
            exit 1
        fi
    ) >/tmp/version-resolution-output.log 2>&1; then
        fail "Copilot installer resolves ${scenario} releases with curl available"
    fi
    pass "Copilot installer resolves ${scenario} releases with curl available"
done

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