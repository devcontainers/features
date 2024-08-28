#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/powershell.md
# Maintainer: The VS Code and Codespaces Teams

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

POWERSHELL_VERSION=${VERSION:-"latest"}
POWERSHELL_MODULES="${MODULES:-""}"
POWERSHELL_PROFILE_URL="${POWERSHELLPROFILEURL}"

MICROSOFT_GPG_KEYS_URI="https://packages.microsoft.com/keys/microsoft.asc"
POWERSHELL_ARCHIVE_ARCHITECTURES="amd64"
POWERSHELL_ARCHIVE_VERSION_CODENAMES="stretch buster bionic focal bullseye jammy bookworm noble"
GPG_KEY_SERVERS="keyserver hkp://keyserver.ubuntu.com
keyserver hkp://keyserver.ubuntu.com:80
keyserver hkps://keys.openpgp.org
keyserver hkp://keyserver.pgp.com"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

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

install_using_apt() {
    # Install dependencies
    check_packages apt-transport-https curl ca-certificates gnupg2 dirmngr
    # Import key safely (new 'signed-by' method rather than deprecated apt-key approach) and install
    curl -sSL ${MICROSOFT_GPG_KEYS_URI} | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/microsoft-${ID}-${VERSION_CODENAME}-prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/microsoft.list

    # Update lists
    apt-get update -yq

    # Soft version matching for CLI
    if [ "${POWERSHELL_VERSION}" = "latest" ] || [ "${POWERSHELL_VERSION}" = "lts" ] || [ "${POWERSHELL_VERSION}" = "stable" ]; then
        # Empty, meaning grab whatever "latest" is in apt repo
        version_suffix=""
    else    
        version_suffix="=$(apt-cache madison powershell | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "^(${POWERSHELL_VERSION})(\.|$|\+.*|-.*)")"

        if [ -z ${version_suffix} ] || [ ${version_suffix} = "=" ]; then
            echo "Provided POWERSHELL_VERSION (${POWERSHELL_VERSION}) was not found in the apt-cache for this package+distribution combo";
            return 1
        fi
        echo "version_suffix ${version_suffix}"
    fi

    apt-get install -yq powershell${version_suffix} || return 1
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
    prev_version=${!variable_name}
    
    output=$(curl -s "$repo_url");
    check_packages jq
    message=$(echo "$output" | jq -r '.message')
    
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
    pwsh_url=$1
    repo_url=$(get_github_api_repo_url $pwsh_url)
    echo -e "\n(!) Failed to fetch the latest artifacts for powershell v${POWERSHELL_VERSION}..."
    get_previous_version $pwsh_url $repo_url POWERSHELL_VERSION
    echo -e "\nAttempting to install v${POWERSHELL_VERSION}"
    install_pwsh "${POWERSHELL_VERSION}"
}

install_pwsh() {
    POWERSHELL_VERSION=$1
    powershell_filename="powershell-${POWERSHELL_VERSION}-linux-${architecture}.tar.gz"
    powershell_target_path="/opt/microsoft/powershell/$(echo ${POWERSHELL_VERSION} | grep -oE '[^\.]+' | head -n 1)"
    mkdir -p /tmp/pwsh "${powershell_target_path}"
    cd /tmp/pwsh
    curl -sSL -o "${powershell_filename}" "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/${powershell_filename}"
}

install_using_github() {
    # Fall back on direct download if no apt package exists in microsoft pool
    check_packages curl ca-certificates gnupg2 dirmngr libc6 libgcc1 libgssapi-krb5-2 libstdc++6 libunwind8 libuuid1 zlib1g libicu[0-9][0-9]
    if ! type git > /dev/null 2>&1; then
        check_packages git
    fi
    if [ "${architecture}" = "amd64" ]; then
        architecture="x64"
    fi
    pwsh_url="https://github.com/PowerShell/PowerShell"
    find_version_from_git_tags POWERSHELL_VERSION $pwsh_url
    install_pwsh "${POWERSHELL_VERSION}"
    if grep -q "Not Found" "${powershell_filename}"; then 
        install_prev_pwsh $pwsh_url
    fi

    # Ugly - but only way to get sha256 is to parse release HTML. Remove newlines and tags, then look for filename followed by 64 hex characters.
    curl -sSL -o "release.html" "https://github.com/PowerShell/PowerShell/releases/tag/v${POWERSHELL_VERSION}"
    powershell_archive_sha256="$(cat release.html | tr '\n' ' ' | sed 's|<[^>]*>||g' | grep -oP "${powershell_filename}\s+\K[0-9a-fA-F]{64}" || echo '')"
    if [ -z "${powershell_archive_sha256}" ]; then
        echo "(!) WARNING: Failed to retrieve SHA256 for archive. Skipping validaiton."
    else
        echo "SHA256: ${powershell_archive_sha256}"
        echo "${powershell_archive_sha256} *${powershell_filename}" | sha256sum -c -
    fi
    tar xf "${powershell_filename}" -C "${powershell_target_path}"
    chmod 755 "${powershell_target_path}/pwsh"
    ln -sf "${powershell_target_path}/pwsh" /usr/bin/pwsh
    add-shell "/usr/bin/pwsh"
    cd /tmp
    rm -rf /tmp/pwsh
}

if ! type pwsh >/dev/null 2>&1; then
    export DEBIAN_FRONTEND=noninteractive
    
    # Source /etc/os-release to get OS info
    . /etc/os-release
    architecture="$(dpkg --print-architecture)"

    if [[ "${POWERSHELL_ARCHIVE_ARCHITECTURES}" = *"${architecture}"* ]] && [[  "${POWERSHELL_ARCHIVE_VERSION_CODENAMES}" = *"${VERSION_CODENAME}"* ]]; then
        install_using_apt || use_github="true"
    else
        use_github="true"
    fi
    
    if [ "${use_github}" = "true" ]; then
        echo "Attempting install from GitHub release..."
        install_using_github
    fi
else
    echo "PowerShell is already installed."
fi

# If PowerShell modules are requested, loop through and install
if [ ${#POWERSHELL_MODULES[@]} -gt 0 ]; then
    echo "Installing PowerShell Modules: ${POWERSHELL_MODULES}"
    modules=(`echo ${POWERSHELL_MODULES} | tr ',' ' '`)
    for i in "${modules[@]}"
    do
        module_parts=(`echo ${i} | tr '==' ' '`)
        module_name="${module_parts[0]}"  
        args="-Name ${module_name} -AllowClobber -Force -Scope AllUsers"  
        if [ "${#module_parts[@]}" -eq 2 ]; then
            module_version="${module_parts[1]}"
            echo "Installing ${module_name} v${module_version}"
            args+=" -RequiredVersion ${module_version}"
        else
            echo "Installing latest version for ${i} module"
        fi

        pwsh -Command "Install-Module $args" || continue
    done
fi


# If URL for powershell profile is provided, download it to '/opt/microsoft/powershell/7/profile.ps1'
if [ -n "$POWERSHELL_PROFILE_URL" ]; then
    echo "Downloading PowerShell Profile from: $POWERSHELL_PROFILE_URL"
    # Get profile path from currently installed pwsh
    profilePath=$(pwsh -noni -c '$PROFILE.AllUsersAllHosts')
    sudo -E curl -sSL -o "$profilePath" "$POWERSHELL_PROFILE_URL"
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
