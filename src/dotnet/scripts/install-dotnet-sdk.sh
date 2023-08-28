#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The Dev Container spec maintainers
fetch_latest_sdk_version_in_channel() {
    local channel="$1"
    wget -qO- "https://dotnetcli.azureedge.net/dotnet/Sdk/$channel/latest.version"
}

fetch_latest_sdk_version() {
    local sts_version
    local lts_version
    sts_version=$(fetch_latest_sdk_version_in_channel "STS")
    lts_version=$(fetch_latest_sdk_version_in_channel "LTS")
    if [[ "$sts_version" > "$lts_version" ]]; then
        echo "$sts_version"
    else
        echo "$lts_version"
    fi
}

install_dotnet_sdk() {
    # Quick options reminder for dotnet-install.sh:
    #
    # --version: 'latest' (default) or an exact version in the form 'A.B.C' like '6.0.413'
    # --channel: 'LTS' (default), 'STS', a two-part version in the form 'A.B' like '6.0' or three-part form 'A.B.Cxx' like '6.0.1xx'
    # --quality: 'daily', 'signed', 'validated', 'preview' or 'GA'
    #
    # The channel option is only used when version is 'latest' because an exact version overrides the channel option
    # The quality option is only used when channel is 'A.B' or 'A.B.Cxx' because it can't be used with STS or LTS

    # This script aims to reduce these combinations of options to a single 'version' input
    local inputVersion="$1"
    local version=""
    local channel=""
    if [[ "$inputVersion" == "latest" ]]; then
        # Fetch the latest version manually, because dotnet-install.sh does not support it directly
        version=$(fetch_latest_sdk_version)
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
    elif [[ "$inputVersion" =~ ^[0-9]+\.[0-9]+\.[0-9]xx$ ]]; then
        # When user input is form 'A.B.Cxx' like '6.0.4xx'
        # Then version=latest, channel=6.0.4xx
        version="latest"
        channel="$inputVersion"
    else
        # Assume version is an exact version string like '6.0.413' or '8.0.100-rc.2.23425.18'
        version="$inputVersion"
        channel=""
    fi

    # Valid examples
    #
    # dotnet-install.sh [--version latest] [--channel LTS]
    # dotnet-install.sh [--version latest] --channel STS
    # dotnet-install.sh [--version latest] --channel 6.0 [--quality GA]
    # dotnet-install.sh [--version latest] --channel 6.0.4xx [--quality GA]
    # dotnet-install.sh [--version latest] --channel 8.0 --quality preview
    # dotnet-install.sh [--version latest] --channel 8.0 --quality daily
    # dotnet-install.sh --version 6.0.413
    
    # Currently this script does not make it possible to qualify the version, 'GA' is always implied
    echo "Executing $DOTNET_INSTALL_SCRIPT --version $version --channel $channel --install-dir $DOTNET_INSTALL_DIR --no-path"
    "$DOTNET_INSTALL_SCRIPT" \
        --version "$version" \
        --channel "$channel" \
        --install-dir "$DOTNET_INSTALL_DIR" \
        --no-path
}