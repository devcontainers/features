#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Maintainer: The VS Code and Codespaces Teams

set -eux

# Clean up
rm -rf /var/lib/apt/lists/*

# Configuration
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi
        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt-get update..."
            apt-get update -y
        fi
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_cmake_version() {
    REQUIRED_CMAKE_VERSION="3.18"
    set +e
    INSTALLED_CMAKE_VERSION=$(cmake --version | head -n1 | cut -d " " -f3)
    set -e

    if [ -z "${INSTALLED_CMAKE_VERSION}" ]; then
        echo "CMake not found. Installing CMake ${REQUIRED_CMAKE_VERSION}..."
        install_cmake "${REQUIRED_CMAKE_VERSION}"
    else
        if ! printf '%s\n%s\n' "${REQUIRED_CMAKE_VERSION}" "${INSTALLED_CMAKE_VERSION}" | sort -V -C; then
            echo "CMake version ${INSTALLED_CMAKE_VERSION} is too old. Installing CMake ${REQUIRED_CMAKE_VERSION}..."
            install_cmake "${REQUIRED_CMAKE_VERSION}"
        else
            echo "CMake version ${INSTALLED_CMAKE_VERSION} meets the requirement."
        fi
    fi
}

install_pony() {
    # Install Pony
    git clone https://github.com/ponylang/ponyc.git
    cd ponyc
    make config=release
    make install config=release
    cd ..
    rm -rf ponyc

    # Update PATH
    updaterc "if [[ \"\${PATH}\" != *\"/usr/local/bin\"* ]]; then export PATH=\"/usr/local/bin:\${PATH}\"; fi"
}

# Install Pony dependencies
PONY_DEPS="build-essential cmake git zlib1g-dev libncurses5-dev libssl-dev llvm-3.9-dev"

# Install dependencies
check_packages $PONY_DEPS

# Check and install CMake if needed
check_cmake_version

# Install Pony language
install_pony

echo "Done!"