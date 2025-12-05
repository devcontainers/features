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

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}    
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local escaped_separator=${separator//./\\.}
        local last_part
        if [ "${last_part_optional}" = "true" ]; then
            last_part="(${escaped_separator}[0-9]+)?"
        else
            last_part="${escaped_separator}[0-9]+"
        fi
        local regex="${prefix}\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
        local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

install_using_github() {
    check_packages wget
    arch=$(dpkg --print-architecture)

    find_version_from_git_tags CLI_VERSION https://github.com/github/copilot-cli
    cli_filename="copilot_linux_${arch}.tar.gz"

    mkdir -p /tmp/copilotcli
    pushd /tmp/copilotcli
    wget -q --show-progress --progress=dot:giga https://github.com/github/copilot-cli/releases/download/v${CLI_VERSION}/${cli_filename}
    exit_code=$?
    set -e
    if [ "$exit_code" != "0" ]; then
        # Fallback to latest version if the specified version does not exist
        echo "(!) copilot-cli version ${CLI_VERSION} failed to download. Attempting to fall back to latest version..."
        wget -q --show-progress --progress=dot:giga https://github.com/github/copilot-cli/releases/latest/download/${cli_filename}
    fi

    tar -xzf /tmp/copilotcli/${cli_filename}
    mv copilot /usr/local/bin/copilot
    popd
    rm -rf /tmp/copilotcli
}

# Install the GitHub Copilot CLI
echo "Downloading GitHub Copilot CLI..."

install_using_github

