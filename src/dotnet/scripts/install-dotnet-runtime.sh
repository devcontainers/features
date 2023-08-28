#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The Dev Container spec maintainers
fetch_latest_dotnet_runtime_version_in_channel() {
    local channel="$1"
    wget -qO- "https://dotnetcli.azureedge.net/dotnet/Runtime/$channel/latest.version"
}

fetch_latest_dotnet_runtime_version() {
    local sts_version
    local lts_version
    sts_version=$(fetch_latest_dotnet_runtime_version_in_channel "STS")
    lts_version=$(fetch_latest_dotnet_runtime_version_in_channel "LTS")
    if [[ "$sts_version" > "$lts_version" ]]; then
        echo "$sts_version"
    else
        echo "$lts_version"
    fi
}

install_dotnet_runtime() {
    local inputVersion="$1"
    local version=""
    local channel=""
    if [[ "$inputVersion" == "latest" ]]; then
        # Fetch the latest version manually, because dotnet-install.sh does not support it directly
        version=$(fetch_latest_dotnet_runtime_version)
        channel=""
    elif [[ "$inputVersion" == "lts" ]]; then
        # When user input is 'lts'
        # Then version=latest, channel=LTS
        version="latest"
        channel="LTS"
    elif [[ "$inputVersion" =~ ^[0-9]+\.[0-9]+$ ]]; then
        # When user input is form 'A.B' like '3.1'
        # Then version=latest, channel=3.1
        version="latest"
        channel="$inputVersion"
    else
        # Assume version is an exact version string like '6.0.21' or '8.0.0-rc.2.23426.4'
        version="$inputVersion"
        channel=""
    fi
    
    echo "Executing $DOTNET_INSTALL_SCRIPT --runtime dotnet --version $version --channel $channel --install-dir $DOTNET_INSTALL_DIR --no-path"
    "$DOTNET_INSTALL_SCRIPT" \
        --runtime dotnet \
        --version "$version" \
        --channel "$channel" \
        --install-dir "$DOTNET_INSTALL_DIR" \
        --no-path
}