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
DOTNET_RUNTIME_ONLY="${RUNTIMEONLY:-"false"}"

DOTNET_INSTALL_SCRIPT_URL='https://dot.net/v1/dotnet-install.sh'
DOTNET_INSTALL_SCRIPT_SHA256='3d5a87bc29fb96e8dac8c2f88d95ff619c3a921903b4c9ff720e07ca0906d55e  /tmp/dotnet-install.sh'
DOTNET_INSTALL_SCRIPT='/tmp/dotnet-install.sh'
DOTNET_INSTALL_DIR='/usr/local/dotnet/current'

set -e

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

# Installs a version of .NET using the DOTNET_INSTALLER_SCRIPT
# The version must be 'latest', use the form 'X', or use the form 'X.Y.Z'
install_version() {
    local version="$1"
    local channel="STS"
    local runtime_arg=""

    echo "Installing version '$version'..."

    # If version is just a major value (form 'X'), assume it is a channel
    if [[ "$version" =~ ^[0-9]+$ ]]; then
        channel="$version.0"
        version="latest"
    fi

    # If version is 'lts', then update the channel
    if [ "$version" = "lts" ]; then
        channel="LTS"
        version="latest"
    fi

    # Make sure the version is formatted correctly (form 'X' is handled before this)
    if ! [[ "$version" = "latest" || "$version" =~ ^[0-9]+.[0-9]+.[0-9]+$ ]]; then
        echo "Invalid version '$version': version must be 'latest' or use the form 'X.Y.Z'"
        return 1
    fi

    if [ "$DOTNET_RUNTIME_ONLY" = 'true' ]; then
        echo "Installing runtime only..."
        runtime_arg='--runtime dotnet'
    fi

    "$DOTNET_INSTALL_SCRIPT" \
        --install-dir "$DOTNET_INSTALL_DIR" \
        --version "$version" \
        --channel "$channel" \
        $runtime_arg
}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# icu-devtools includes dependencies for .NET
check_packages wget ca-certificates icu-devtools

wget -O "$DOTNET_INSTALL_SCRIPT" "$DOTNET_INSTALL_SCRIPT_URL"
sha256sum --check <<< $DOTNET_INSTALL_SCRIPT_SHA256
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
