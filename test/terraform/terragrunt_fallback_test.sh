#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

set_error_handler() {
    echo "Error occurred on line: $LINENO"
}

# Register the error handler function to be triggered on ERR signal
trap 'set_error_handler' ERR

check "terragrunt version as installed by feature" terragrunt --version

TERRAGRUNT_SHA256="automatic"

architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

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


# Function to fetch the version released prior to the latest version
get_previous_version() {
    local url=$1
    local repo_url=$2
    local variable_name=$3
    local mode=$4
    prev_version=${!variable_name}
    
    output=$(curl -s "$repo_url");
    # install jq if not exists
    if ! type jq > /dev/null 2>&1; then
        check_packages jq
    fi
    message=$(echo "$output" | jq -r '.message')
    if [[ "$mode" == "mode1" ]]; then
        message="API rate limit exceeded";
    elif [[ "$mode" == "mode2" ]]; then
        message=""
    fi 
    if [[ $message == "API rate limit exceeded"* ]]; then
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

get_pkg_name() {
    local input_string="$1"
    local lowercase_input="${input_string,,}"  # Convert to lowercase
    local suffix="_version"
    local substring="${lowercase_input%$suffix*}"  # Remove suffix and everything after it
    echo "$substring"
}

install_previous_version() {
    given_version=$1
    requested_version=${!given_version}
    local URL=$2
    local mode=$3
    local REPO_URL=$(get_github_api_repo_url "$URL")
    local PKG_NAME=$(get_pkg_name "${given_version}")
    echo -e "\n(!) Failed to fetch the latest artifacts for ${PKG_NAME} v${requested_version}..."
    get_previous_version "$URL" "$REPO_URL" requested_version $mode
    echo -e "\nAttempting to install ${requested_version}"
    declare -g ${given_version}="${requested_version#v}"
    INSTALLER_FN="install_${PKG_NAME}"
    $INSTALLER_FN "${!given_version}"
    echo "${given_version}=${!given_version}"
}


install_terragrunt() {
    TERRAGRUNT_VERSION=$1
    curl -sSL -o /tmp/tf-downloads/${terragrunt_filename} https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/${terragrunt_filename}
}


try_install_dummy_terragrunt_version() {
    mode=$1
    mkdir -p /tmp/tf-downloads
    cd /tmp/tf-downloads
    terragrunt_url='https://github.com/gruntwork-io/terragrunt'
    TERRAGRUNT_VERSION="0.55.xyz"
    echo -e "\nAttempting to install terragrunt dummy v${TERRAGRUNT_VERSION}"
    echo "Downloading Terragrunt... v${TERRAGRUNT_VERSION}"
    terragrunt_filename="terragrunt_linux_${architecture}"
    install_terragrunt "$TERRAGRUNT_VERSION"
    output=$(cat "/tmp/tf-downloads/${terragrunt_filename}")
    if [[ $output == "Not Found" ]]; then
        install_previous_version TERRAGRUNT_VERSION $terragrunt_url $mode
    fi
    if [ "${TERRAGRUNT_SHA256}" != "dev-mode" ]; then
        if [ "${TERRAGRUNT_SHA256}" = "automatic" ]; then
            curl -sSL -o terragrunt_SHA256SUMS https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/SHA256SUMS
        else
            echo "${TERRAGRUNT_SHA256} *${terragrunt_filename}" > terragrunt_SHA256SUMS
        fi
        sha256sum --ignore-missing -c terragrunt_SHA256SUMS
    fi
    sudo chmod a+x /tmp/tf-downloads/${terragrunt_filename}
    sudo mv -f /tmp/tf-downloads/${terragrunt_filename} /usr/local/bin/terragrunt
}

try_install_dummy_terragrunt_version "mode1"

check "terragrunt version as installed by test after fallbacking from the dummy version (mode 1: install using find_prev_version_from_git_tags)" terragrunt --version

try_install_dummy_terragrunt_version "mode2"

check "terragrunt version as installed by test after fallbacking from the dummy version (mode 2: install using GitHub Api)" terragrunt --version

# Report result
reportResults

