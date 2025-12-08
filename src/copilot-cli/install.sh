#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/blob/main/src/copilot-cli/README.md
# Maintainer: The VS Code and Codespaces Teams

CLI_VERSION=${VERSION:-"latest"}

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

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

download_from_github() {
    local release_url=$1
    echo "Downloading GitHub Copilot CLI from ${release_url}..."

    mkdir -p /tmp/copilotcli
    pushd /tmp/copilotcli
    wget --show-progress --progress=dot:giga ${release_url}
    # curl -fL# -O ${release_url}
    tar -xzf /tmp/copilotcli/${cli_filename}
    mv copilot /usr/local/bin/copilot
    popd
    rm -rf /tmp/copilotcli
}

install_using_github() {
    check_packages wget tar ca-certificates git
    echo "Finished setting up dependencies"
    arch=$(dpkg --print-architecture)
    if [ "${arch}" = "amd64" ]; then
        arch="x64"
    fi
    if [ "${arch}" != "x64" ] && [ "${arch}" != "arm64" ]; then
        echo "Unsupported architecture: ${arch}" >&2
        exit 1
    fi
    cli_filename="copilot-linux-${arch}.tar.gz"
    echo "Installing GitHub Copilot CLI for ${arch} architecture: ${cli_filename}"

    # Install latest
    if [ "${CLI_VERSION}" = "latest" ]; then
        download_from_github "https://github.com/github/copilot-cli/releases/latest/download/${cli_filename}"
    elif [ "${CLI_VERSION}" = "prerelease" ]; then
        prerelease_version="$(git ls-remote --tags https://github.com/github/copilot-cli | tail -1 | awk -F/ '{print $NF}')"
        download_from_github "https://github.com/github/copilot-cli/releases/download/${prerelease_version}/${cli_filename}"
    else
        # Install specific version
        download_from_github "https://github.com/github/copilot-cli/releases/download/${CLI_VERSION}/${cli_filename}"
    fi
}

# Install the GitHub Copilot CLI
echo "Downloading GitHub Copilot CLI..."

install_using_github

