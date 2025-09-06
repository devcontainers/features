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
# Usage: install_sdk <version> [<quality>]
# Example: install_sdk "9.0"
# Example: install_sdk "10.0" "preview"
install_sdk() {
    local inputVersion="$1" # Could be 'latest', 'lts', 'X.Y', 'X.Y.Z', 'X.Y.4xx', or base channel when paired with quality
    local quality="$2"      # Optional quality: GA, preview, daily (empty implies GA)
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
    
    local cmd=("$DOTNET_INSTALL_SCRIPT" "--version" "$version" "--install-dir" "$DOTNET_ROOT")
    if [ -n "$channel" ]; then
        cmd+=("--channel" "$channel")
    fi
    if [ -n "$quality" ]; then
        cmd+=("--quality" "$quality")
    fi
    echo "Executing ${cmd[*]}"
    "${cmd[@]}"
}

# Installs a version of the .NET Runtime
# Usage: install_runtime <runtime> <version> [<quality>]
# Example: install_runtime "dotnet" "9.0"
# Example: install_runtime "aspnetcore" "10.0" "preview"
install_runtime() {
    local runtime="$1"
    local inputVersion="$2" # Could be 'latest', 'lts', 'X.Y', 'X.Y.Z'
    local quality="$3"      # Optional quality: GA, preview, daily (empty implies GA)
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

    local cmd=("$DOTNET_INSTALL_SCRIPT" "--runtime" "$runtime" "--version" "$version" "--install-dir" "$DOTNET_ROOT" "--no-path")
    if [ -n "$channel" ]; then
        cmd+=("--channel" "$channel")
    fi
    if [ -n "$quality" ]; then
        cmd+=("--quality" "$quality")
    fi
    echo "Executing ${cmd[*]}"
    "${cmd[@]}"
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

# Input: version spec possibly containing -preview or -daily
# Supports channels in the forms:
#   A.B            (e.g. 10.0)
#   A.B.Cxx        (feature band e.g. 6.0.4xx)
#   A.B-preview    (adds quality)
#   A.B-daily
#   A.B.Cxx-preview
#   A.B.Cxx-daily
# Output (stdout): "<clean_version> <quality>"
#   - For channel specs (A.B or A.B.Cxx) without suffix -> quality is GA
#   - For channel specs with -preview/-daily suffix -> quality is preview/daily
#   - For exact version specs (contain a third numeric segment or prerelease labels beyond channel patterns, e.g. 8.0.100-rc.2.23502.2) -> quality is empty
# Examples:
#   parse_version_and_quality "10.0-preview"    => "10.0 preview"
#   parse_version_and_quality "10.0-daily"      => "10.0 daily"
#   parse_version_and_quality "10.0"            => "10.0 GA"
#   parse_version_and_quality "6.0.4xx"         => "6.0.4xx GA"
#   parse_version_and_quality "6.0.4xx-preview" => "6.0.4xx preview"
#   parse_version_and_quality "6.0.4xx-daily"   => "6.0.4xx daily"
parse_version_and_quality() {
    local input="$1"
    local quality=""
    local clean_version="$input"
    # Match feature band with quality
    if [[ "$input" =~ ^([0-9]+\.[0-9]+\.[0-9]xx)-(preview|daily)$ ]]; then
        clean_version="${BASH_REMATCH[1]}"
        quality="${BASH_REMATCH[2]}"
    # Match simple channel with quality
    elif [[ "$input" =~ ^([0-9]+\.[0-9]+)-(preview|daily)$ ]]; then
        clean_version="${BASH_REMATCH[1]}"
        quality="${BASH_REMATCH[2]}"
    # Match plain feature band channel (defaults to GA)
    elif [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]xx$ ]]; then
        clean_version="$input"
        quality="GA"
    # Match simple channel (defaults to GA)
    elif [[ "$input" =~ ^[0-9]+\.[0-9]+$ ]]; then
        clean_version="$input"
        quality="GA"
    else
        # Exact version (leave quality empty)
        clean_version="$input"
        quality=""
    fi
    echo "$clean_version" "$quality"
}