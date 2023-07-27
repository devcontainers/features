#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The VS Code and Codespaces Teams
DOTNET_VERSION="${VERSION:-"latest"}"
DOTNET_ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

DOTNET_INSTALL_SCRIPT_URL='https://dot.net/v1/dotnet-install.sh'
DOTNET_INSTALL_SCRIPT='/tmp/dotnet-install.sh'
DOTNET_INSTALL_DIR='/usr/share/dotnet'

set -e

# Setup STDERR.
err() {
    echo "(!) $*" >&2
}

apt_get_update() {
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

fetch_latest_sdk_version_in_channel() {
    local channel="$1"
    wget -qO- "https://dotnetcli.azureedge.net/dotnet/Sdk/$channel/latest.version"
}

fetch_latest_sdk_version() {
    local latest_STS=$(fetch_latest_sdk_version_in_channel "STS")
    local latest_LTS=$(fetch_latest_sdk_version_in_channel "LTS")
    if [[ "$latest_STS" > "$latest_LTS" ]]; then
        echo "$latest_STS"
    else
        echo "$latest_LTS"
    fi
}

# Installs a version of .NET using the DOTNET_INSTALLER_SCRIPT
install_version() {
    local version="$1"
    local channel="STS"

    echo "Installing version '$version'..."

    # Quick options reminder for dotnet-install.sh:
    #
    # --version: 'latest' (default) or an exact version in the form 'A.B.C' like '6.0.412'
    # --channel: 'LTS' (default), 'STS', a two-part version in the form 'A.B' like '6.0' or three-part form 'A.B.Cxx' like '6.0.1xx'
    # --quality: 'daily', 'signed', 'validated', 'preview' or 'GA'
    #
    # Valid examples
    #
    # dotnet-install.sh [--version latest] --channel LTS
    # dotnet-install.sh [--version latest] --channel STS
    # dotnet-install.sh [--version latest] --channel 6.0 [--quality GA]
    # dotnet-install.sh [--version latest] --channel 6.0.4xx [--quality GA]
    # dotnet-install.sh [--version latest] --channel 8.0 --quality preview
    # dotnet-install.sh [--version latest] --channel 8.0 --quality daily
    # dotnet-install.sh --version 6.0.412
    #
    # The channel option is only used when version is 'latest' because an exact version overrides the channel option
    # The quality option is only used when channel is 'A.B' or 'A.B.Cxx' because it can't be used with STS or LTS
    #
    # This script aims to reduce these combinations of options to a single 'version' input
    # Currently this script does not make it possible to request a version in the form 'A.B' or 'A.B.Cxx' and a quality other than 'GA'
    if [[ "$version" == "latest" ]]; then
        # Fetch the latest version manually, because dotnet-install.sh does not support it directly
        version=$(fetch_latest_sdk_version)
        channel=""
    elif [[ "$version" == "lts" ]]; then
        # When user input is 'lts'
        # Then version=latest, channel=LTS
        channel="LTS"
        version="latest"
    elif [[ "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        # When user input is form 'A.B' like '3.1'
        # Then version=latest, channel=3.1
        channel="$version"
        version="latest"
    elif [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]xx$ ]]; then
        # When user input is form 'A.B.Cxx' like '6.0.4xx'
        # Then version=latest, channel=6.0.4xx
        channel="$version"
        version="latest"
    else
        # Assume version is an exact version string like '6.0.412' or '8.0.100-rc.1.23371.5''
        channel=""
    fi

    echo "Executing $DOTNET_INSTALL_SCRIPT --install-dir $DOTNET_INSTALL_DIR --version $version --channel $channel"
    "$DOTNET_INSTALL_SCRIPT" \
        --install-dir "$DOTNET_INSTALL_DIR" \
        --version "$version" \
        --channel "$channel"
}

if [ "$(id -u)" -ne 0 ]; then
    err 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# icu-devtools includes dependencies for .NET
check_packages wget ca-certificates icu-devtools

wget -O "$DOTNET_INSTALL_SCRIPT" "$DOTNET_INSTALL_SCRIPT_URL"
chmod +x "$DOTNET_INSTALL_SCRIPT"

# Install primary version
install_version "$DOTNET_VERSION"

# Install additional versions
if [ -n "$DOTNET_ADDITIONAL_VERSIONS" ]; then
    OLD_IFS=$IFS
    IFS=","
        read -a additional_versions <<< "$DOTNET_ADDITIONAL_VERSIONS"
        for version in "${additional_versions[@]}"; do
            # Trim whitespace from version
            version="$(echo -e "$version" | tr -d '[:space:]')"
            install_version "$version"
        done
    IFS=$OLD_IFS
fi

rm "$DOTNET_INSTALL_SCRIPT"

echo "Done!"
