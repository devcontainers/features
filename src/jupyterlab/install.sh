#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/jupyterlab.md
# Maintainer: The VS Code and Codespaces Teams

set -ex

VERSION=${VERSION:-"latest"}
PYTHON=${PYTHON_BINARY:-"python"}

USERNAME=${USERNAME:-"automatic"}
ALLOW_ALL_ORIGINS=${ALLOW_ALL_ORIGINS:-""}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# If in automatic mode, determine if a user already exists, if not use vscode
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=vscode
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
fi

addToJupyterConfig() {
  JUPYTER_DIR="/home/${USERNAME}/.jupyter"
  JUPYTER_CONFIG="${JUPYTER_DIR}/jupyter_notebook_config.py"

  # Make sure the config file exists
  test -d ${JUPYTER_DIR} || mkdir ${JUPYTER_DIR}
  test -f ${JUPYTER_CONFIG} || touch ${JUPYTER_CONFIG}

  # Don't write the same line more than once
  grep -q ${1} ${JUPYTER_CONFIG} || echo ${1} >> ${JUPYTER_CONFIG}
}

# Make sure that Python is available
if ! ${PYTHON} --version > /dev/null ; then
  echo "You need to install Python before installing JupyterLab."
  exit 1
fi

# pip skips installation if JupyterLab is already installed
echo "Installing JupyterLab..."
if [ "${VERSION}" = "latest" ]; then
  ${PYTHON} -m pip install jupyterlab --no-cache-dir
else
  ${PYTHON} -m pip install jupyterlab=="${VERSION}" --no-cache-dir
fi

if [ "${ALLOW_ALL_ORIGINS}" = 'true' ]; then
  addToJupyterConfig "c.ServerApp.allow_origin = '*'"
  addToJupyterConfig "c.NotebookApp.allow_origin = '*'"
fi