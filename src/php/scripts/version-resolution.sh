#!/usr/bin/env bash

# Resolve version requests from git tags, with a caller-provided fallback resolver.
# The fallback function must print candidate versions, one per line.
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    local version_suffix_regex=${6:-""}
    local fallback_name=${7:-""}
    local fallback_function=${8:-""}
    local known_good_version=${9:-""}

    if [ -z "${fallback_function}" ] && echo "${repository}" | grep -qE '^https://github.com/[^/]+/[^/]+/?$'; then
        fallback_name="GitHub REST API"
        fallback_function="_github_rest_version_candidates"
    fi
    if [ -z "${known_good_version}" ]; then
        known_good_version="$(_known_good_version_for_repository "${repository}")"
    fi

    if [ "${requested_version}" = "none" ]; then
        return
    fi

    local escaped_separator=${separator//./\.}
    local patch_regex="${escaped_separator}[0-9]+"
    if [ "${last_part_optional}" = "true" ]; then
        patch_regex="(${patch_regex})?"
    fi
    local version_regex="[0-9]+${escaped_separator}[0-9]+${patch_regex}${version_suffix_regex//./\.}"

    # Fully qualified versions are user assertions. Do not require the network
    # to prove that a requested release exists.
    if echo "${requested_version}" | grep -Eq "^${version_regex}$"; then
        echo "${variable_name}=${requested_version}"
        return
    fi

    local version_list=""
    local git_output=""
    if git_output="$(git ls-remote --tags "${repository}" 2>/dev/null)"; then
        version_list="$(_extract_version_candidates "${git_output}" "${prefix}" "${separator}" "${version_regex}")"
    fi

    if [ -z "${version_list}" ]; then
        echo "(!) Unable to resolve '${requested_version}' from git tags at ${repository}." >&2
        if [ -n "${fallback_function}" ]; then
            echo "(*) Trying ${fallback_name:-alternate version source}." >&2
            local fallback_output=""
            if fallback_output="$(${fallback_function} "${repository}" "${prefix}" 2>/dev/null)"; then
                version_list="$(_normalize_version_candidates "${fallback_output}" "${separator}" "${version_regex}")"
            fi
            if [ -n "${version_list}" ]; then
                echo "(*) Resolved version using ${fallback_name:-alternate version source}." >&2
            fi
        fi
    fi

    local resolved_version=""
    resolved_version="$(_select_requested_version "${requested_version}" "${version_list}")"
    if [ -z "${resolved_version}" ] && [ -n "${known_good_version}" ] && _version_matches_request "${requested_version}" "${known_good_version}"; then
        resolved_version="${known_good_version}"
        echo "(!) Dynamic version resolution failed; using known-good version ${known_good_version}." >&2
    fi

    if [ -z "${resolved_version}" ]; then
        echo "(!) Unable to resolve '${requested_version}' for ${variable_name}. Tried git tags at ${repository}${fallback_name:+ and ${fallback_name}}. Specify an exact version to avoid remote resolution." >&2
        return 1
    fi

    declare -g "${variable_name}=${resolved_version}"
    echo "${variable_name}=${resolved_version}"
}

_github_rest_version_candidates() {
    local repository=$1
    local prefix=${2:-"tags/v"}
    local slug=${repository#https://github.com/}
    slug=${slug%/}
    local tag_prefix=${prefix#refs/}
    tag_prefix=${tag_prefix#tags/}

    curl -fsSL "https://api.github.com/repos/${slug}/tags?per_page=100" \
        | grep -oE '"name"[[:space:]]*:[[:space:]]*"[^"]+"' \
        | sed -E 's/^.*"([^"]+)"$/\1/' \
        | sed "s|^${tag_prefix}||"
}

_known_good_version_for_repository() {
    case ${1%/} in
        https://github.com/docker/compose) echo "5.5.1" ;;
        https://github.com/docker/compose-switch) echo "1.0.5" ;;
        https://github.com/docker/buildx) echo "0.37.1" ;;
        https://github.com/cli/cli) echo "2.101.0" ;;
        https://github.com/git-lfs/git-lfs) echo "3.8.0" ;;
        https://github.com/helm/helm) echo "4.3.0" ;;
        https://github.com/kubernetes/kubernetes) echo "1.37.0" ;;
        https://github.com/kubernetes/minikube) echo "1.39.0" ;;
        https://github.com/NixOS/nix) echo "2.35.2" ;;
        https://github.com/nvm-sh/nvm) echo "0.40.8" ;;
        https://github.com/php/php-src) echo "8.5.10" ;;
        https://github.com/xdebug/xdebug) echo "3.5.3" ;;
        https://github.com/PowerShell/PowerShell) echo "7.6.6" ;;
        https://github.com/python/cpython) echo "3.14.7" ;;
        https://github.com/openssl/openssl) echo "4.0.2" ;;
        https://github.com/sigstore/cosign) echo "3.1.3" ;;
        https://github.com/rust-lang/rust) echo "1.98.1" ;;
        https://github.com/hashicorp/terraform) echo "1.16.3" ;;
        https://github.com/terraform-linters/tflint) echo "0.64.0" ;;
        https://github.com/gruntwork-io/terragrunt) echo "1.1.5" ;;
        https://github.com/aquasecurity/tfsec) echo "1.28.14" ;;
        https://github.com/terraform-docs/terraform-docs) echo "0.24.0" ;;
        https://github.com/github/copilot-cli) echo "1.0.87-0" ;;
    esac
}

_extract_version_candidates() {
    local input=$1
    local prefix=$2
    local separator=$3
    local version_regex=$4
    local escaped_prefix=${prefix//./\.}

    printf '%s\n' "${input}" \
        | grep -oE "${escaped_prefix}${version_regex}$" \
        | sed "s|^${prefix}||" \
        | tr "${separator}" "." \
        | sort -rVu || true
}

_normalize_version_candidates() {
    local input=$1
    local separator=$2
    local version_regex=$3

    printf '%s\n' "${input}" \
        | grep -oE "^${version_regex}$" \
        | tr "${separator}" "." \
        | sort -rVu || true
}

_select_requested_version() {
    local requested_version=$1
    local version_list=$2

    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "stable" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "prerelease" ] || [ "${requested_version}" = "preview" ]; then
        printf '%s\n' "${version_list}" | head -n 1
        return
    fi

    printf '%s\n' "${version_list}" | grep -E -m 1 "^${requested_version//./\.}([.]|[-]|$)" || true
}

_version_matches_request() {
    local requested_version=$1
    local candidate=$2

    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "stable" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "prerelease" ] || [ "${requested_version}" = "preview" ]; then
        return 0
    fi

    echo "${candidate}" | grep -Eq "^${requested_version//./\.}([.]|[-]|$)"
}