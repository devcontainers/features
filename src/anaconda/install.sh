#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/anaconda.md
# Maintainer: The VS Code and Codespaces Teams


VERSION=${VERSION:-"latest"}
USERNAME=${USERNAME:-"automatic"}
UPDATE_RC=${UPDATE_RC:-"true"}
CONDA_DIR="/opt/conda"

set -eux
export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u "${CURRENT_USER}" > /dev/null 2>&1; then
            USERNAME="${CURRENT_USER}"
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

architecture="$(uname -m)"
if [ "${architecture}" != "x86_64" ]; then
    echo "(!) Architecture $architecture unsupported"
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
        apt-get update -y
        apt-get -y install --no-install-recommends "$@"

        # Clean up
        apt-get clean -y
        rm -rf /var/lib/apt/lists/*
    fi
}

# Install Conda if it's missing
if ! conda --version &> /dev/null ; then
    if ! cat /etc/group | grep -e "^conda:" > /dev/null 2>&1; then
        groupadd -r conda
    fi
    usermod -a -G conda "${USERNAME}"

    # Install dependencies
    check_packages curl ca-certificates gnupg2

    echo "Installing Anaconda..."

    curl -sS https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > /usr/share/keyrings/conda-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" > /etc/apt/sources.list.d/conda.list

    CONDA_PKG="conda=${VERSION}-0"
    if [ "${VERSION}" = "latest" ]; then
        CONDA_PKG="conda"
    fi

    check_packages $CONDA_PKG

    CONDA_SCRIPT="/opt/conda/etc/profile.d/conda.sh"
    . $CONDA_SCRIPT

    conda config --add channels conda-forge
    conda config --set channel_priority strict
    conda config --set env_prompt '({name})'
    echo "source ${CONDA_SCRIPT}" >> ~/.bashrc

    chown -R "${USERNAME}:conda" "${CONDA_DIR}"
    chmod -R g+r+w "${CONDA_DIR}"
    
    find "${CONDA_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s

    updaterc "export CONDA_DIR=${CONDA_DIR}/bin"
fi

echo "Done!"