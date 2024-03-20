#!/bin/bash

# Optional: Import test library
source dev-container-features-test-lib

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

HL="\033[1;33m"
N="\033[0;37m"
echo -e "\n👉${HL} docker-compose version as installed by docker-in-docker feature${N}"
check "docker-compose" bash -c "docker-compose version"

architecture="$(dpkg --print-architecture)"
case "${architecture}" in
    amd64) target_compose_arch=x86_64 ;;
    arm64) target_compose_arch=aarch64 ;;
    *)
        echo "(!) Docker in docker does not support machine architecture '$architecture'. Please use an x86-64 or ARM64 machine."
        exit 1
esac

docker_compose_path="/usr/local/bin/docker-compose"
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

fetch_use_local_function() {
    local url=$1
    local version=$2
    vers=${!version}
    find_prev_version_from_git_tags vers "${url}" "tags/v"
    declare -g ${version}="${vers}"
}

fetch_use_github_api() {
    local url=$1
    local repo_url=$2
    local version=$3
    local mode=$4
    given_version=${!version}
    # Fetch the response headers for the rate limit information and store them in a variable  
    headers=$(curl -s --head -H "Accept: application/json" "${repo_url}")  
    # Extract the rate limit information from the headers  
    read -r limit remaining reset_epoch <<<$(echo "$headers" | grep -oP 'x-ratelimit-(limit|remaining|reset): \K\d+' | tr '\n' ' ')
    # convert remaining to an int value for comparison to be greater than or less than 0  
    local remaining_int=$(printf "%d" "$remaining")

    if [[ "$mode" = "install_from_local_fn" ]]; then 
        remaining_int=0
    fi

    if [[ $remaining_int -gt 0 ]]; then
        curl_output=$(curl -s "${repo_url}" | jq -r '.tag_name')
        declare -g ${version}="${curl_output#v}"
    else
        fetch_use_local_function "${url}" given_version
        declare -g ${version}="${given_version}"
    fi
}

# Function to fetch the version released prior to the latest version
get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    local mode=$4
    prev_version=${!variable_name}
    response=$(curl -s -o /dev/null -w "%{http_code}" "$repo_url")
    if [[ "${mode}" = "install_from_failing_api" ]]; then
        response=403
    fi
    # check if github api url is not found i.e 403 error code returned
    if [ "$response" -eq 403 ]; then
        # if github api url is not found, then simply fetch using find_prev_version_from_git_tags
        fetch_use_local_function "${url}" prev_version
    else 
        # continue fetching from github api
        fetch_use_github_api "${url}" "${repo_url}" prev_version "${mode}"
    fi
    declare -g ${variable_name}="${prev_version}"
}

form_url() {
    local url=$1
    api_url=${url/https:\/\/github.com/https:\/\/api.github.com\/repos}
    api_url="$api_url/releases/latest"
    echo "$api_url"
}

install_using_get_previous_version() {
    local url=$1
    local mode=$2
    local repo_url=$(form_url "$url")
    echo -e "\n(!) Failed to fetch the latest artifacts for docker-compose v${compose_version}..."
    get_previous_version "$url" "$repo_url" compose_version "$mode"
    echo -e "\nAttempting to install v${compose_version}"
    curl -fsSL "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${target_compose_arch}" -o ${docker_compose_path}
}

install_docker_compose() {
    mode=$1
    compose_version="2.25.xyz"
    url_1="https://github.com/docker/compose"
    echo "(*) Installing docker-compose ${compose_version}..."
    curl -fsSL "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${target_compose_arch}" -o ${docker_compose_path} || install_using_get_previous_version "$url_1" "$mode"
}

chmod +x ${docker_compose_path}

# Download the SHA256 checksum
DOCKER_COMPOSE_SHA256="$(curl -sSL "https://github.com/docker/compose/releases/download/v${compose_version}/docker-compose-linux-${target_compose_arch}.sha256" | awk '{print $1}')"
echo "${DOCKER_COMPOSE_SHA256}  ${docker_compose_path}" > docker-compose.sha256sum
sha256sum -c docker-compose.sha256sum --ignore-missing

mkdir -p ${cli_plugins_dir}
cp ${docker_compose_path} ${cli_plugins_dir}

echo -e "\n👉${HL} docker-compose version as installed by docker-in-docker test ( installing by find_prev_version_from_git_tags api when github api-url fails with 403 ) ${N}"
install_docker_compose "install_from_failing_api"

check "docker-compose" bash -c "docker-compose version"

echo -e "\n👉${HL} docker-compose version as installed by docker-in-docker test ( installing by github api ) ${N}"
install_docker_compose "install_from_github_api_valid"

check "docker-compose" bash -c "docker-compose version"

echo -e "\n👉${HL} docker-compose version as installed by docker-in-docker test ( installing by find_prev_version_from_git_tags ) ${N}"
install_docker_compose "install_from_local_fn"

check "docker-compose" bash -c "docker-compose version"
