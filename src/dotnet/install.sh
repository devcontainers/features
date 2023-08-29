#!/bin/bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/dotnet
# Maintainer: The Dev Container spec maintainers
DOTNET_VERSION="${VERSION:-"latest"}"
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"
DOTNET_RUNTIME_VERSIONS="${DOTNETRUNTIMEVERSIONS:-""}"
ASPNETCORE_RUNTIME_VERSIONS="${ASPNETCORERUNTIMEVERSIONS:-""}"

DOTNET_INSTALL_SCRIPT='scripts/vendor/dotnet-install.sh'
DOTNET_INSTALL_DIR='/usr/share/dotnet'

set -e

source "scripts/install-dotnet-sdk.sh"
source "scripts/install-dotnet-runtime.sh"
source "scripts/install-aspnetcore-runtime.sh"

# Clean up
rm -rf /var/lib/apt/lists/*

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

# Removes leading and trailing whitespace from an input string
trim_whitespace() {
    text="$1"

    # Remove leading spaces
    while [ "${text:0:1}" == " " ]; do
        text="${text:1}"
    done

    # Remove trailing spaces
    while [ "${text: -1}" == " " ]; do
        text="${text:0:-1}"
    done

    echo "$text"
}

# Splits comma-separated values into an array while ignoring empty entries
split_csv() {
    local -a values=()
    while IFS="," read -ra entries; do
        for entry in "${entries[@]}"; do
            entry="$(trim_whitespace "$entry")"
            if [ -n "$entry" ]; then
                values+=("$entry")
            fi
        done
    done <<< "$1"

    echo "${values[@]}"
}

if [ "$(id -u)" -ne 0 ]; then
    err 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# For our own convenience, combine DOTNET_VERSION and ADDITIONAL_VERSIONS into a single 'versions' array
versions=()

# The version can be set to 'none' for runtime-only installations, then the array will just remain empty
# Ensure there are no leading or trailing spaces that can break regex pattern matching
if [ "$DOTNET_VERSION" != "none" ]; then
    versions+=("$(trim_whitespace "$DOTNET_VERSION")")
    for additional_version in $(split_csv "$ADDITIONAL_VERSIONS"); do
        versions+=("$additional_version")
    done
fi

dotnetRuntimeVersions=()
for dotnetRuntimeVersion in $(split_csv "$DOTNET_RUNTIME_VERSIONS"); do
    dotnetRuntimeVersions+=("$dotnetRuntimeVersion")
done

aspNetCoreRuntimeVersions=()
for aspNetCoreRuntimeVersion in $(split_csv "$ASPNETCORE_RUNTIME_VERSIONS"); do
    aspNetCoreRuntimeVersions+=("$aspNetCoreRuntimeVersion")
done

# Fail fast in case of bad input to avoid unneccesary work
# v1 of the .NET feature allowed specifying only a major version 'X' like '3'
# v2 removed this ability
# - because install-dotnet.sh does not support it directly
# - because the previous behavior installed an old version like '3.0.103', not the newest version '3.1.426', which was counterintuitive
for version in "${versions[@]}"; do
    if [[ "$version" =~ ^[0-9]+$ ]]; then
        err "Unsupported .NET SDK version '${version}'. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version."
        exit 1
    fi
done

for version in "${dotnetRuntimeVersions[@]}"; do
    if [[ "$version" =~ ^[0-9]+$ ]]; then
        err "Unsupported .NET Runtime version '${version}'. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version."
        exit 1
    fi
done

for version in "${aspNetCoreRuntimeVersions[@]}"; do
    if [[ "$version" =~ ^[0-9]+$ ]]; then
        err "Unsupported ASP.NET Core Runtime version '${version}'. Use 'latest' for the latest version, 'lts' for the latest LTS version, 'X.Y' or 'X.Y.Z' for a specific version."
        exit 1
    fi
done

# Install .NET versions and dependencies
# icu-devtools includes dependencies for .NET
check_packages wget ca-certificates icu-devtools

for version in "${versions[@]}"; do
    install_dotnet_sdk "$version"
done

for version in "${dotnetRuntimeVersions[@]}"; do
    install_dotnet_runtime "$version"
done

for version in "${aspNetCoreRuntimeVersions[@]}"; do
    install_aspnetcore_runtime "$version"
done

# Clean up
rm -rf /var/lib/apt/lists/*
rm -rf scripts

echo "Done!"
