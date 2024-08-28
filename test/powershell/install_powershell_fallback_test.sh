#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Extension-specific tests
check "az.resources" pwsh -Command "(Get-Module -ListAvailable -Name Az.Resources).Version.ToString()"
check "az.storage" pwsh -Command "(Get-Module -ListAvailable -Name Az.Storage).Version.ToString()"
check "profile" pwsh -Command "if (\$null -eq \$env:ProfileLoaded) { echo 'Not set!'; exit 1 } else { if ( [bool]\$env:ProfileLoaded ) { echo 'Profile loaded.'; exit 0 } else { echo 'False value!'; exit 1 } }"

check "Powershell version as installed by feature" bash -c "pwsh --version"

. /etc/os-release
architecture="$(dpkg --print-architecture)"

sudo mkdir -p /var/lib/apt/lists/

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

install_prev_pwsh() {
    local pwsh_url=$1
    local mode=$2
    local repo_url=$(get_github_api_repo_url $pwsh_url)
    echo -e "\n(!) Failed to fetch the latest artifacts for powershell v${POWERSHELL_VERSION}..."
    get_previous_version $pwsh_url $repo_url POWERSHELL_VERSION $mode
    echo -e "\nAttempting to install v${POWERSHELL_VERSION}"
    install_pwsh "${POWERSHELL_VERSION}"
}

install_pwsh() {
    POWERSHELL_VERSION=$1
    powershell_filename="powershell-${POWERSHELL_VERSION}-linux-${architecture}.tar.gz"
    powershell_target_path="/opt/microsoft/powershell/$(echo ${POWERSHELL_VERSION} | grep -oE '[^\.]+' | head -n 1)"
    sudo mkdir -p /tmp/pwsh "${powershell_target_path}"
    cd /tmp/pwsh
    sudo curl -sSL -o "${powershell_filename}" "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/${powershell_filename}"
}

install_using_github() {
    mode=$1
    if [ "${architecture}" = "amd64" ]; then
        architecture="x64"
    fi
    pwsh_url="https://github.com/PowerShell/PowerShell"
    POWERSHELL_VERSION="7.4.xyz"
    install_pwsh "${POWERSHELL_VERSION}"
    if grep -q "Not Found" "${powershell_filename}"; then 
        install_prev_pwsh $pwsh_url $mode
    fi

    # Ugly - but only way to get sha256 is to parse release HTML. Remove newlines and tags, then look for filename followed by 64 hex characters.
    sudo curl -sSL -o "release.html" "https://github.com/PowerShell/PowerShell/releases/tag/v${POWERSHELL_VERSION}"
    powershell_archive_sha256="$(cat release.html | tr '\n' ' ' | sed 's|<[^>]*>||g' | grep -oP "${powershell_filename}\s+\K[0-9a-fA-F]{64}" || echo '')"
    if [ -z "${powershell_archive_sha256}" ]; then
        echo "(!) WARNING: Failed to retrieve SHA256 for archive. Skipping validaiton."
    else
        echo "SHA256: ${powershell_archive_sha256}"
        echo "${powershell_archive_sha256} *${powershell_filename}" | sha256sum -c -
    fi
    sudo tar xf "${powershell_filename}" -C "${powershell_target_path}"
    sudo chmod 755 "${powershell_target_path}/pwsh"
    sudo ln -sf "${powershell_target_path}/pwsh" /usr/bin/pwsh
    sudo add-shell "/usr/bin/pwsh"
    cd /tmp
    sudo rm -rf /tmp/pwsh
}

echo -e "\nInstalling Powershell with find_prev_version_from_git_tags() fn 👈🏻"
install_using_github "mode1"
check "Powershell version as installed by test (find_prev_version_from_git_tags() fn)" bash -c "pwsh --version"

echo -e "\nInstalling Powershell with GitHub Api 👈🏻"
install_using_github "mode2"
check "Powershell version as installed by test (GitHub Api)" bash -c "pwsh --version"

# Report result
reportResults
