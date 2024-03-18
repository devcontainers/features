#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Extension-specific tests
check "az.resources" pwsh -Command "(Get-Module -ListAvailable -Name Az.Resources).Version.ToString()"
check "az.storage" pwsh -Command "(Get-Module -ListAvailable -Name Az.Storage).Version.ToString()"
check "profile" pwsh -Command "(Get-Variable $env:ProfileLoaded).Value"

check "Powershell version as installed by feature" bash -c "pwsh --version"

. /etc/os-release
architecture="$(dpkg --print-architecture)"

get_previous_version() {
    repo_url=$1
    curl -s "$repo_url" | jq -r 'del(.[].assets) | .[0].tag_name'
}

install_prev_pwsh() {
    echo -e "\n(!) Failed to fetch the latest artifacts for powershell v${POWERSHELL_VERSION}..."
    previous_version=$(get_previous_version "https://api.github.com/repos/PowerShell/PowerShell/releases")
    echo -e "\nAttempting to install ${previous_version}"
    POWERSHELL_VERSION="${previous_version#v}"
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

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        sudo apt-get update -y
    fi
}

check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        sudo chmod +x /var/lib/apt/lists/
        sudo mkdir -p /var/lib/apt/lists/partial
        sudo chmod +rx /var/lib/dpkg/lock-frontend
        apt_get_update
        sudo apt-get -y install --no-install-recommends "$@"
    fi
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

    echo -e "\nTrying to install a non-existing version for Powershell..."

    POWERSHELL_VERSION="1.2.XYZ"
    install_pwsh "${POWERSHELL_VERSION}"

    if grep -q "Not Found" "${powershell_filename}"; then
        install_prev_pwsh
    fi

    echo -e "\n" $POWERSHELL_VERSION "=powershell_version\n";
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
    sudo ln -s "${powershell_target_path}/pwsh" /usr/local/bin/pwsh
    sudo rm -rf /tmp/pwsh
}

install_using_github

check "Powershell version as installed by test" bash -c "pwsh --version"

# Report result
reportResults
