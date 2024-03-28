#!/bin/bash
set -e

# Optional: Import test library
source dev-container-features-test-lib
HL="\033[1;33m"
N="\033[0;37m"
echo -e "\n👉${HL} helm version as installed by kubectl-helm-minikube feature${N}:"

set +e
    check "helm version" helm version
set -e

# Function to handle errors
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command=$2
    echo "Error occurred at line $line_number with exit code $exit_code in command $command"
    exit $exit_code
}
trap 'handle_error $LINENO ${BASH_COMMAND%% *}' ERR
echo "This is line $LINENO"

## Check for fallback version installation instead of latest ( when artifact not found )
architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

helm_url="https://github.com/helm/helm"

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
    prev_version=${!variable_name#v}
    
    output=$(curl -s "$repo_url");

    message=$(echo "$output" | jq -r '.message')

    if [ $mode == "mode1" ]; then
        message="API rate limit exceeded"
    else 
        message=""
    fi

    if [[ $message == "API rate limit exceeded"* ]]; then
        echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
        echo -e "\nAttempting to find latest version using GitHub tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v"
        declare -g ${variable_name}="v${prev_version}"
    else 
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.tag_name')
        declare -g ${variable_name}="${version}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}

get_helm() {
    HELM_VERSION=$1
    helm_filename="helm-${HELM_VERSION}-linux-${architecture}.tar.gz"
    tmp_helm_filename="/tmp/helm/${helm_filename}"
    sudo curl -sSL "https://get.helm.sh/${helm_filename}" -o "${tmp_helm_filename}"
    sudo curl -sSL "https://github.com/helm/helm/releases/download/${HELM_VERSION}/${helm_filename}.asc" -o "${tmp_helm_filename}.asc"
}

install_helm() {
    mode=$1
    HELM_VERSION="v3.14.xyz"
    echo -e "\n👉Trying to install HELM_VERSION = ${HELM_VERSION}"; 
    sudo mkdir -p /tmp/helm
    get_helm "${HELM_VERSION}"
    if grep -q "BlobNotFound" "/tmp/helm/${helm_filename}"; then
        echo -e "\n(!) Failed to fetch the latest artifacts for helm ${HELM_VERSION}..."
        repo_url=$(get_github_api_repo_url "${helm_url}")
        get_previous_version "${helm_url}" "${repo_url}" HELM_VERSION $mode
        echo -e "\nAttempting to install ${HELM_VERSION}"
        get_helm "${HELM_VERSION}"
    fi
}

echo -e "\n👉${HL} helm version as installed by test for fallback${N}: (mode1: installation using find_prev_version_using_git_tags() fn)"
install_helm "mode1"

set +e
    check "helm version" helm version
set -e

echo -e "\n👉${HL} helm version as installed by test for fallback${N}: (mode2: installation using GitHub api)"
install_helm "mode2"

set +e
    check "helm version" helm version
set -e

# Report result
reportResults
