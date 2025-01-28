#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The Dev Container spec maintainers
DOTNET_SCRIPTS=$(dirname "${BASH_SOURCE[0]}")
DOTNET_INSTALL_SCRIPT="$DOTNET_SCRIPTS/vendor/dotnet-install.sh"

# Prints the latest dotnet version in the specified channel
# Usage: fetch_latest_version_in_channel <channel> [<runtime>]
# Example: fetch_latest_version_in_channel "LTS"
# Example: fetch_latest_version_in_channel "6.0" "dotnet"
# Example: fetch_latest_version_in_channel "6.0" "aspnetcore"
fetch_latest_version_in_channel() {
    local channel="$1"
    local runtime="$2"
    if [ "$runtime" = "dotnet" ]; then
        wget -qO- "https://builds.dotnet.microsoft.com/dotnet/Runtime/$channel/latest.version"
    elif [ "$runtime" = "aspnetcore" ]; then
        wget -qO- "https://builds.dotnet.microsoft.com/dotnet/aspnetcore/Runtime/$channel/latest.version"
    else
        wget -qO- "https://builds.dotnet.microsoft.com/dotnet/Sdk/$channel/latest.version"
    fi
}

# Prints the latest dotnet version
# Usage: fetch_latest_version [<runtime>]
# Example: fetch_latest_version
# Example: fetch_latest_version "dotnet"
# Example: fetch_latest_version "aspnetcore"
fetch_latest_version() {
    local runtime="$1"
    local sts_version
    local lts_version
    sts_version=$(fetch_latest_version_in_channel "STS" "$runtime")
    lts_version=$(fetch_latest_version_in_channel "LTS" "$runtime")
    if [[ "$sts_version" > "$lts_version" ]]; then
        echo "$sts_version"
    else
        echo "$lts_version"
    fi
}

# Installs a version of the .NET SDK
# Usage: install_sdk <version>
install_sdk() {
    local inputVersion="$1"
    local version=""
    local channel=""
    if [[ "$inputVersion" == "latest" ]]; then
        # Fetch the latest version manually, because dotnet-install.sh does not support it directly
        version=$(fetch_latest_version)
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
    fi
    
    # Currently this script does not make it possible to qualify the version, 'GA' is always implied
    echo "Executing $DOTNET_INSTALL_SCRIPT --version $version --channel $channel --install-dir $DOTNET_ROOT"
    "$DOTNET_INSTALL_SCRIPT" \
        --version "$version" \
        --channel "$channel" \
        --install-dir "$DOTNET_ROOT"
}

# Installs a version of the .NET Runtime
# Usage: install_runtime <runtime> <version>
install_runtime() {
    local runtime="$1"
    local inputVersion="$2"
    local version=""
    local channel=""
    if [[ "$inputVersion" == "latest" ]]; then
        # Fetch the latest version manually, because dotnet-install.sh does not support it directly
        version=$(fetch_latest_version "$runtime")
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
        # Assume version is an exact version string like '6.0.21' or '8.0.0-preview.7.23375.6'
        version="$inputVersion"
    fi
    
    echo "Executing $DOTNET_INSTALL_SCRIPT --runtime $runtime --version $version --channel $channel --install-dir $DOTNET_ROOT --no-path"
    "$DOTNET_INSTALL_SCRIPT" \
        --runtime "$runtime" \
        --version "$version" \
        --channel "$channel" \
        --install-dir "$DOTNET_ROOT" \
        --no-path
}

# Installs one or more .NET workloads
# Usage: install_workload <workload_id> [<workload_id> ...]
# Reference: https://docs.microsoft.com/en-us/dotnet/core/tools/dotnet-workload-install
install_workloads() {
    local workloads="$@"

    echo "Installing .NET workload(s) $workloads"
    dotnet workload install $workloads --temp-dir /tmp/dotnet-workload-temp-dir

    # Clean up
    rm -r /tmp/dotnet-workload-temp-dir
}
