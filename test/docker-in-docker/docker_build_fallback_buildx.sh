#!/bin/bash

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Definition specific tests before test for fallback
HL="\033[1;33m"
N="\033[0;37m"
echo -e "\n👉${HL} docker/buildx version as installed by docker-in-docker feature${N}"
check "docker-buildx" docker buildx version
check "docker-build" docker build ./
check "docker-buildx" bash -c "docker buildx version"
check "docker-buildx-path" bash -c "ls -la /usr/libexec/docker/cli-plugins/docker-buildx"

# Code to test the made up scenario when latest version of docker/buildx fails on wget command for fetching the artifacts
architecture="$(dpkg --print-architecture)"
case "${architecture}" in
    amd64) target_compose_arch=x86_64 ;;
    arm64) target_compose_arch=aarch64 ;;
    *)
        echo "(!) Docker in docker does not support machine architecture '$architecture'. Please use an x86-64 or ARM64 machine."
        exit 1
esac

docker_home="/usr/libexec/docker"
cli_plugins_dir="${docker_home}/cli-plugins"

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
        err "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
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
    
    echo -e "\nAttempting to find latest version using Github Api."

    output=$(curl -s "$repo_url");
    message=$(echo "$output" | jq -r '.message')

    if [[ $mode != "install_from_github_api_valid" ]]; then 
        message="API rate limit exceeded"
    fi
    
    if [[ $message == "API rate limit exceeded"* ]]; then
        echo -e "\nAttempting to find latest version using Github Api Failed. Exceeded API Rate Limit."
        echo -e "\nAttempting to find latest version using Github Tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v"
        declare -g ${variable_name}="${prev_version}"
    else 
        echo -e "\nAttempting to find latest version using Github Api Succeeded."
        version=$(echo "$output" | jq -r '.tag_name')
        declare -g ${variable_name}="${version#v}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}

install_using_get_previous_version() {
    local url=$1
    local mode=$2
    local repo_url=$(get_github_api_repo_url "$url")
    echo -e "\n(!) Failed to fetch the latest artifacts for docker buildx v${buildx_version}..."
    get_previous_version "${url}" "${repo_url}" buildx_version "${mode}"
    buildx_file_name="buildx-v${buildx_version}.linux-${architecture}"
    echo -e "\nAttempting to install v${buildx_version}"
    wget https://github.com/docker/buildx/releases/download/v${buildx_version}/${buildx_file_name}
}
    
install_docker_buildx() {
    mode=$1
    echo -e "\n${HL} Creating a scenario for fallback${N}\n"

    buildx_version="0.13.xyz"
    echo "(*) Installing buildx ${buildx_version}..."
    buildx_file_name="buildx-v${buildx_version}.linux-${architecture}"
    cd /tmp

    docker_buildx_url="https://github.com/docker/buildx"
    wget https://github.com/docker/buildx/releases/download/v${buildx_version}/${buildx_file_name} || install_using_get_previous_version "${docker_buildx_url}" "${mode}"
    
    docker_home="/usr/libexec/docker"
    cli_plugins_dir="${docker_home}/cli-plugins"

    mkdir -p ${cli_plugins_dir}
    mv ${buildx_file_name} ${cli_plugins_dir}/docker-buildx
    chmod +x ${cli_plugins_dir}/docker-buildx

    chown -R "${USERNAME}:docker" "${docker_home}"
    chmod -R g+r+w "${docker_home}"
    find "${docker_home}" -type d -print0 | xargs -n 1 -0 chmod g+s
}

echo -e "\n👉${HL} docker-buildx version as installed by docker-in-docker test ( installing by github api ) ${N}"
install_docker_buildx "install_from_github_api_valid"

# Definition specific tests after test for fallback
check "docker-buildx" docker buildx version
check "docker-buildx" bash -c "docker buildx version"

echo -e "\n👉${HL} docker-buildx version as installed by docker-in-docker test ( installing by find_prev_version_from_git_tags ) ${N}"
install_docker_buildx

# Definition specific tests after test for fallback
check "docker-buildx" docker buildx version
check "docker-buildx" bash -c "docker buildx version"

# Report result
reportResults
