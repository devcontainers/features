#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The VS Code and Codespaces Teams

VERSION="${VERSION:-"latest"}"
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"
RUNTIME_ONLY="${RUNTIMEONLY:-"false"}"

INSTALL_DIR="/usr/local/dotnet/current"

set -e

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

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Install dependencies
check_packages wget ca-certificates icu-devtools

# apt-transport-https curl  gnupg2 dirmngr

# Download installer
installer_script="/tmp/dotnet-install.sh"

wget -O "$installer_script" https://dot.net/v1/dotnet-install.sh
chmod +x "$installer_script"

# Install primary version
"$installer_script" --install-dir "$INSTALL_DIR"

# ./dotnet-install.sh  -v "$DOTNET_3_LIVESHARE_VERSION" --install-dir /home/codespace/.dotnet

echo "Done!"
