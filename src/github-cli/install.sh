#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/github.md
# Maintainer: The VS Code and Codespaces Teams

CLI_VERSION=${VERSION:-"latest"}
INSTALL_DIRECTLY_FROM_GITHUB_RELEASE=${INSTALLDIRECTLYFROMGITHUBRELEASE:-"true"}
TEST_EXPORT=${TEST_EXPORT:-}

GITHUB_CLI_ARCHIVE_GPG_KEY=23F3D4EA75716059
GPG_KEY_SERVERS="keyserver hkp://keyserver.ubuntu.com:80
keyserver hkps://keys.openpgp.org
keyserver hkp://keyserver.pgp.com"

set -e

if [ "$(id -u)" -ne 0 ] && [ -z "$TEST_EXPORT" ]; then
    echo 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.' >&2
    exit 1
fi

# Get central common setting
get_common_setting() {
    if [ "${common_settings_file_loaded}" != "true" ]; then
        curl -sfL "https://aka.ms/vscode-dev-containers/script-library/settings.env" 2>/dev/null -o /tmp/vsdc-settings.env || echo "Could not download settings file. Skipping."
        common_settings_file_loaded=true
    fi
    if [ -f "/tmp/vsdc-settings.env" ]; then
        local multi_line=""
        if [ "$2" = "true" ]; then multi_line="-z"; fi
        local result="$(grep ${multi_line} -oP "$1=\"?\K[^\"]+" /tmp/vsdc-settings.env | tr -d '\0')"
        if [ ! -z "${result}" ]; then declare -g $1="${result}"; fi
    fi
    echo "$1=${!1}"
}

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    get_common_setting $1
    local keys=${!1}
    get_common_setting GPG_KEY_SERVERS true

    # Use a temporary locaiton for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo -e "disable-ipv6\n${GPG_KEY_SERVERS}" > ${GNUPGHOME}/dirmngr.conf
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; 
    do
        echo "(*) Downloading GPG key..."
        ( echo "${keys}" | xargs -n 1 gpg --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retring in 10s..."
            (( retry_count++ ))
            sleep 10s
        fi
    done
    set -e
    if [ "${gpg_ok}" = "false" ]; then
        echo "(!) Failed to get gpg key."
        exit 1
    fi
}

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    get_common_setting $1
    local keys=${!1}
    get_common_setting GPG_KEY_SERVERS true
    local keyring_args=""
    if [ ! -z "$2" ]; then
        keyring_args="--no-default-keyring --keyring $2"
    fi

    # Use a temporary locaiton for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo -e "disable-ipv6\n${GPG_KEY_SERVERS}" > ${GNUPGHOME}/dirmngr.conf
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; 
    do
        echo "(*) Downloading GPG key..."
        ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retring in 10s..."
            (( retry_count++ ))
            sleep 10s
        fi
    done
    set -e
    if [ "${gpg_ok}" = "false" ]; then
        echo "(!) Failed to get gpg key."
        exit 1
    fi
}

ran_apt_get_update="false"

# Runs `apt-get update` at most once
apt_get_update() {
    [ "$ran_apt_get_update" != "true" ] || return 0
    echo "Running apt-get update..."
    apt-get update -y
    ran_apt_get_update="true"
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Print latest git versions that match an optional version prefix
find_version_from_git_tags() {
    local prefix="${1:-}"
    git ls-remote --tags --sort=-version:refname https://github.com/cli/cli.git | while read -r _ ref; do
        version="${ref#refs/tags/v}"
        if [[ $version != *-* && ( -z $prefix || "${version}." == "${prefix}."* ) ]]; then
            printf "%s\n" "$version"
        fi
    done
}

# For each version, fetch a .deb file from releases and install the first available one with dpkg
install_deb_using_github() {
    local arch="$(dpkg --print-architecture)"
    local version download_url
    for version; do
        download_url="https://github.com/cli/cli/releases/download/v${version}/gh_${version}_linux_${arch}.deb"
        wget -P /tmp/ghcli "$download_url" || continue
        dpkg -i "/tmp/ghcli/$(basename "$download_url")"
        break
    done
    rm -rf /tmp/ghcli
}

if [ -n "$TEST_EXPORT" ]; then
    # print function named by TEST_EXPORT and exit
    declare -f "$TEST_EXPORT"
    exit 0
fi

check_packages ca-certificates
type -P git >/dev/null || check_packages git

is_latest="false"

case "$CLI_VERSION" in
none )
    # opt out of installing gh
    exit 0
    ;;
latest | lts | stable | current )
    # find two latest versions
    versions=( $(find_version_from_git_tags | head -n2) )
    is_latest="true"
    ;;
*.*.* )
    # the exact version is specified explicitly
    versions=( "$CLI_VERSION" )
    ;;
* )
    # find two latest versions matching version prefix
    versions=( $(find_version_from_git_tags "$CLI_VERSION" | head -n2) )
    ;;
esac

if [ "${#versions[@]}" -eq 0 ]; then
    printf 'error: no git tags in the cli/cli repository matched version "%s"\n' "$CLI_VERSION" >&2
    exit 1
fi

# Install the GitHub CLI
echo "Downloading github CLI..."

if [ "${INSTALL_DIRECTLY_FROM_GITHUB_RELEASE}" = "true" ]; then
    check_packages wget
    install_deb_using_github "${versions[@]}"
elif [ "$is_latest" != "true" ]; then
    # In its current implementation, the https://cli.github.com/packages repository does not retain older versions of gh,
    # so we cannot allow installing arbitrary versions with the `apt-get install gh=VERSION` syntax.
    printf 'error: cannot install non-latest version when "installDirectlyFromGitHubRelease" is disabled\n' >&2
    exit 1
else
    check_packages curl apt-transport-https dirmngr gnupg2
    # Import key safely (new method rather than deprecated apt-key approach) and install
    . /etc/os-release
    receive_gpg_keys GITHUB_CLI_ARCHIVE_GPG_KEY /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list
    apt-get update
    apt-get -y install gh
    rm -rf "/tmp/gh/gnupg"
    echo "Done!"
fi
