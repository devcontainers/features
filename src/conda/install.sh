#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

VERSION=${VERSION:-"latest"}
ADD_CONDA_FORGE=$ADDCONDAFORGE

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="true"
CONDA_DIR="/opt/conda"

set -eux
export DEBIAN_FRONTEND=noninteractive

# Clean up
rm -rf /var/lib/apt/lists/*

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

# Source common helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/_lib/common-setup.sh"

# Determine the appropriate non-root user
USERNAME=$(determine_user_from_input "${USERNAME}" "root")

architecture="$(uname -m)"
if [ "${architecture}" != "x86_64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

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

sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        $COMMAND
    fi
}

install_user_package() {
    PACKAGE="$1"
    sudo_if "${CONDA_DIR}/bin/python3" -m pip install --user --upgrade "$PACKAGE"
}

# Install Conda if it's missing
if ! conda --version &> /dev/null ; then
    if ! cat /etc/group | grep -e "^conda:" > /dev/null 2>&1; then
        groupadd -r conda
    fi
    usermod -a -G conda "${USERNAME}"

    # Install dependencies
    check_packages curl ca-certificates

    echo "Installing Conda..."

    # Download .deb package directly from repository (bypassing SHA1 signature issue)
    TEMP_DEB="$(mktemp -t conda_XXXXXX.deb)"
    CONDA_REPO_BASE="https://repo.anaconda.com/pkgs/misc/debrepo/conda"
    
    # Determine package filename based on requested version
    ARCH="$(dpkg --print-architecture 2>/dev/null || echo "amd64")"
    PACKAGES_URL="https://repo.anaconda.com/pkgs/misc/debrepo/conda/dists/stable/main/binary-${ARCH}/Packages"
    
    if [ "${VERSION}" = "latest" ]; then
        # For latest, we need to query the repository to find the current version
        echo "Fetching package list to determine latest version..."
        CONDA_PKG_INFO=$(curl -fsSL "${PACKAGES_URL}" | grep -A 30 "^Package: conda$" | head -n 31)
        CONDA_VERSION=$(echo "${CONDA_PKG_INFO}" | grep "^Version:" | head -n 1 | awk '{print $2}')
        CONDA_FILENAME=$(echo "${CONDA_PKG_INFO}" | grep "^Filename:" | head -n 1 | awk '{print $2}')
        
        if [ -z "${CONDA_VERSION}" ] || [ -z "${CONDA_FILENAME}" ]; then
            echo "ERROR: Could not determine latest conda version or filename from ${PACKAGES_URL}"
            echo "This may indicate an unsupported architecture or repository unavailability."
            rm -f "${TEMP_DEB}"
            exit 1
        fi
        
        CONDA_PKG_NAME="${CONDA_FILENAME}"
    else
        # For specific versions, query the Packages file to find the exact filename
        echo "Fetching package list to find version ${VERSION}..."
        # Search for version pattern - user may specify 4.12.0 but package has 4.12.0-0
        CONDA_PKG_INFO=$(curl -fsSL "${PACKAGES_URL}" | grep -A 30 "^Package: conda$" | grep -B 5 -A 25 "^Version: ${VERSION}")
        CONDA_FILENAME=$(echo "${CONDA_PKG_INFO}" | grep "^Filename:" | head -n 1 | awk '{print $2}')
        
        if [ -z "${CONDA_FILENAME}" ]; then
            echo "ERROR: Could not find conda version ${VERSION} in ${PACKAGES_URL}"
            echo "Please verify the version specified is valid."
            rm -f "${TEMP_DEB}"
            exit 1
        fi
        
        CONDA_PKG_NAME="${CONDA_FILENAME}"
    fi
    
    # Download the .deb package
    CONDA_DEB_URL="${CONDA_REPO_BASE}/${CONDA_PKG_NAME}"
    echo "Downloading conda package from ${CONDA_DEB_URL}..."
    
    if ! curl -fsSL "${CONDA_DEB_URL}" -o "${TEMP_DEB}"; then
        echo "ERROR: Failed to download conda .deb package from ${CONDA_DEB_URL}"
        echo "Please verify the version specified is valid."
        rm -f "${TEMP_DEB}"
        exit 1
    fi
    
    # Verify the package was downloaded successfully
    if [ ! -f "${TEMP_DEB}" ] || [ ! -s "${TEMP_DEB}" ]; then
        echo "ERROR: Conda .deb package file is missing or empty"
        rm -f "${TEMP_DEB}"
        exit 1
    fi
    
    # Install the package using apt (which handles dependencies automatically)
    echo "Installing conda package..."
    if ! apt-get install -y "${TEMP_DEB}"; then
        echo "ERROR: Failed to install conda package"
        rm -f "${TEMP_DEB}"
        exit 1
    fi
    
    # Clean up downloaded package
    rm -f "${TEMP_DEB}"

    CONDA_SCRIPT="/opt/conda/etc/profile.d/conda.sh"
    . $CONDA_SCRIPT

    if [ "${ADD_CONDA_FORGE}" = "true" ]; then
        conda config --add channels conda-forge
    fi

    conda config --set channel_priority strict
    conda config --set env_prompt '({name})'
    echo "source ${CONDA_SCRIPT}" >> ~/.bashrc

    chown -R "${USERNAME}:conda" "${CONDA_DIR}"
    chmod -R g+r+w "${CONDA_DIR}"
    
    find "${CONDA_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s

    # Temporary fixes
    # Due to https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23491
    install_user_package certifi
    # Due to https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-0286 and https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-23931
    install_user_package cryptography
    # Due to https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-40897
    install_user_package setuptools
fi

# Display a notice on conda when not running in GitHub Codespaces
mkdir -p /usr/local/etc/vscode-dev-containers
cat << 'EOF' > /usr/local/etc/vscode-dev-containers/conda-notice.txt
When using "conda" from outside of GitHub Codespaces, note the Anaconda repository contains
restrictions on commercial use that may impact certain organizations. See https://aka.ms/ghcs-conda

EOF

notice_script="$(cat << 'EOF'
if [ -t 1 ] && [ "${IGNORE_NOTICE}" != "true" ] && [ "${TERM_PROGRAM}" = "vscode" ] && [ "${CODESPACES}" != "true" ] && [ ! -f "$HOME/.config/vscode-dev-containers/conda-notice-already-displayed" ]; then
    cat "/usr/local/etc/vscode-dev-containers/conda-notice.txt"
    mkdir -p "$HOME/.config/vscode-dev-containers"
    ((sleep 10s; touch "$HOME/.config/vscode-dev-containers/conda-notice-already-displayed") &)
fi
EOF
)"

if [ -f "/etc/zsh/zshrc" ]; then
    echo "${notice_script}" | tee -a /etc/zsh/zshrc
fi

if [ -f "/etc/bash.bashrc" ]; then
    echo "${notice_script}" | tee -a /etc/bash.bashrc
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
