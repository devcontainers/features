#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/hugo.md
# Maintainer: The VS Code and Codespaces Teams
#
# Syntax: ./oryx-debian.sh [Non-root user]

USERNAME=${1:-"automatic"}
UPDATE_RC=${2:-"true"}

set -eu

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
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

function updaterc() {
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

# Function to run apt-get if needed
apt_get_update_if_needed()
{
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update_if_needed
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Install dependencies
check_packages git

# If we don't already have Oryx installed, install it now.
if ! oryx --version > /dev/null ; then
    echo "Installing Oryx..."

    # Install dotnet unless available
    if ! dotnet --version > /dev/null ; then
        echo $(pwd)
        cd ../dotnet
        echo $(ls)
        echo $($(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)) 
        chmod +x ../dotnet/install.sh
        sudo ../dotnet/install.sh latest false ${USERNAME} ${UPDATE_RC} /usr/local/dotnet
    fi

    BUILD_SCRIPT_GENERATOR=/usr/local/buildscriptgen 
    ORYX=/usr/local/oryx

    mkdir -p ${BUILD_SCRIPT_GENERATOR}
    mkdir -p ${ORYX}

    chown -R ${USERNAME} ${BUILD_SCRIPT_GENERATOR} ${ORYX}
    git clone --depth=1 https://github.com/microsoft/Oryx /tmp/oryx

    /tmp/oryx/build/buildSln.sh

    dotnet publish -property:ValidateExecutableReferencesMatchSelfContained=false -r linux-x64 -o ${BUILD_SCRIPT_GENERATOR} -c Release /tmp/oryx/src/BuildScriptGenerator/BuildScriptGenerator.csproj

    chmod a+x ${BUILD_SCRIPT_GENERATOR}/GenerateBuildScript

    ln -s ${BUILD_SCRIPT_GENERATOR}/GenerateBuildScript ${ORYX}/oryx

    cp -f /tmp/oryx/images/build/benv.sh ${ORYX}/benv

    echo "vso-focal" > ${ORYX}/.imagetype
fi

echo "Done!"
