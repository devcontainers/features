#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests
check "version" gh  --version

find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    local version_suffix_regex=$6
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
    major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
    minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
    breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

    if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
        ((major=major-1))
        declare -g ${variable_name}="${major}"
        # Look for latest version from previous major release
        find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
    # Handle situations like Go's odd version pattern where "0" releases omit the last part
    elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
        ((minor=minor-1))
        declare -g ${variable_name}="${major}.${minor}"
        # Look for latest version from previous minor release
        find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
    else
        ((breakfix=breakfix-1))
        if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
            declare -g ${variable_name}="${major}.${minor}"
        else
            declare -g ${variable_name}="${major}.${minor}.${breakfix}"
        fi
    fi
}

CLI_VERSION="2.20.0"
find_prev_version_from_git_tags CLI_VERSION https://github.com/cli/cli
check "pre-version-to-2.20.0" bash -c "echo ${CLI_VERSION} | grep '2.19.0'"

CLI_VERSION="2.18.1"
find_prev_version_from_git_tags CLI_VERSION https://github.com/cli/cli
check "pre-version-to-2.18.1" bash -c "echo ${CLI_VERSION} | grep '2.18.0'"

CLI_VERSION="2.15.0"
find_prev_version_from_git_tags CLI_VERSION https://github.com/cli/cli
check "pre-version-to-2.15.0" bash -c "echo ${CLI_VERSION} | grep '2.14.7'"

CLI_VERSION="2.0.0"
find_prev_version_from_git_tags CLI_VERSION https://github.com/cli/cli
check "pre-version-to-2.0.0" bash -c "echo ${CLI_VERSION} | grep '1.14.0'"

# Report result
reportResults
