#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

echo -e "\n👉 Checking version of compose-switch installed as docker-compose as installed by feature";
check "installs compose-switch as docker-compose" bash -c "[[ -f /usr/local/bin/docker-compose ]]"

trap 'echo "Last executed command failed at line ${LINENO}"' ERR

# Fetch host/container arch.
architecture="$(dpkg --print-architecture)"

sudo mkdir -p /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Figure out correct version of a three part version number is not passed
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

# Use semver logic to decrement a version number then look for the closest match
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
    set -e
}

# Function to fetch the version released prior to the latest version
get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    local mode=$4
    prev_version=${!variable_name}

    output=$(curl -s "$repo_url");

    check_packages jq

    message=$(echo "$output" | jq -r '.message')
    
    if [[ $message == "API rate limit exceeded"* ]] || [[ $mode == 'mode1' ]]; then
        echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
        echo -e "\nAttempting to find latest version using GitHub tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v"
        declare -g ${variable_name}="${prev_version}"
    else 
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.tag_name')
        declare -g ${variable_name}="${version#v}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}

install_compose_switch_fallback() {
    compose_switch_url=$1
    mode=$2
    repo_url=$(get_github_api_repo_url "${compose_switch_url}")
    echo -e "\n(!) Failed to fetch the latest artifacts for compose-switch v${compose_switch_version}..."
    get_previous_version "${compose_switch_url}" "${repo_url}" compose_switch_version $mode
    echo -e "\nAttempting to install v${compose_switch_version}"
    sudo curl -fsSL "https://github.com/docker/compose-switch/releases/download/v${compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/docker-compose
}

install_compose-switch_as_docker-compose() {
    mode=$1
    echo "(*) Installing compose-switch as docker-compose..."
    compose_switch_version="1.0.6"
    compose_switch_url="https://github.com/docker/compose-switch"
    sudo curl -fsSL "https://github.com/docker/compose-switch/releases/download/v${compose_switch_version}/docker-compose-linux-${architecture}" -o /usr/local/bin/docker-compose || install_compose_switch_fallback "${compose_switch_url}" $mode
    sudo chmod +x /usr/local/bin/docker-compose
}

echo -e "\n👉 Trying to install compose-switch as docker-compose using mode 1 ( find_prev_version_from_git_tags method )";
install_compose-switch_as_docker-compose "mode1"
check "installs compose-switch as docker-compose mode 1" bash -c "[[ -f /usr/local/bin/docker-compose ]]"

echo -e "\n👉 Trying to install compose-switch as docker-compose using mode 2 ( GitHub Api )";
install_compose-switch_as_docker-compose "mode2"
check "installs compose-switch as docker-compose mode 2" bash -c "[[ -f /usr/local/bin/docker-compose ]]"