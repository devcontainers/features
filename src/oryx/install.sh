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

# If in automatic mode, determine if a user already exists, if not use codespace
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
        USERNAME=codespace
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi

# If we don't already have Oryx installed, install it now.
if ! oryx --version > /dev/null ; then
    echo "Installing Oryx..."

    BUILD_SCRIPT_GENERATOR=/usr/local/buildscriptgen 
    ORYX=/usr/local/oryx

    mkdir -p ${BUILD_SCRIPT_GENERATOR}
    mkdir -p ${ORYX}

    chown -R ${USERNAME} ${BUILD_SCRIPT_GENERATOR} ${ORYX}
    git clone --depth=1 https://github.com/microsoft/Oryx /tmp/oryx

    /tmp/oryx/build/buildSln.sh

    dotnet publish -property:ValidateExecutableReferencesMatchSelfContained=false -r linux-x64 -o ${BUILD_SCRIPT_GENERATOR} -c Release /tmp/oryx/src/BuildScriptGenerator\BuildScriptGenerator.csproj

    chmod a+x ${BUILD_SCRIPT_GENERATOR}/GenerateBuildScript

    ln -s ${BUILD_SCRIPT_GENERATOR}/GenerateBuildScript ${ORYX}/oryx

    cp -f /tmp/oryx/images/build/benv.sh ${ORYX}/benv

    echo "vso-focal" > ${ORYX}/.imagetype
fi