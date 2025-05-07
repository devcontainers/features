#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/mise
# Maintainer: The Dev Container spec maintainers

set -eux

# Feature options
MISE_VERSION="${VERSION}"
INSTALL_PLUGINS="${INSTALLPLUGINS:-""}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# Install dependencies based on OS
. /etc/os-release

echo "(*) Installing dependencies for ${ID}..."
if [ "${ID}" = "debian" ] || [ "${ID}" = "ubuntu" ]; then
    apt-get update
    apt-get install -y curl ca-certificates
elif [ "${ID}" = "fedora" ] || [ "${ID}" = "rhel" ] || [ "${ID}" = "centos" ] || [ "${ID}" = "rocky" ] || [ "${ID}" = "almalinux" ]; then
    if command -v dnf >/dev/null; then
        dnf install -y curl
    else
        yum install -y curl
    fi
fi

# Install mise using the appropriate method for the OS
if [ "${MISE_VERSION}" != "none" ]; then
    echo "(*) Installing mise version ${MISE_VERSION}..."

    export MISE_INSTALL_PATH="/usr/local/bin/mise"
    if [ "${MISE_VERSION:-latest}" = "latest" ]; then
      # latest: installer’s default, so don’t set MISE_VERSION
      curl -sSf https://mise.run | sh
    else
      # pinned: pass through MISE_VERSION
      curl -sSf https://mise.run | MISE_VERSION="${MISE_VERSION}" sh
    fi

    # Verify mise is installed
    if command -v mise >/dev/null 2>&1; then
        echo "mise installed successfully: $(mise --version)"
    else
        echo "ERROR: mise installation failed. Could not find mise in PATH."
        exit 1
    fi

    # Install plugins if specified
    if [ -n "${INSTALL_PLUGINS}" ]; then
        echo "Installing mise plugins: ${INSTALL_PLUGINS}"
        IFS=","
        read -ra plugins <<< "${INSTALL_PLUGINS}"
        for plugin in "${plugins[@]}"; do
            echo "Installing plugin: ${plugin}"
            mise plugins install ${plugin}
        done
    fi
else
    echo "Skipping mise installation as 'none' was specified."
fi

echo "Done!"