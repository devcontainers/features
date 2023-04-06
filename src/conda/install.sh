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
    check_packages curl ca-certificates gnupg2

    echo "Installing Conda..."

    curl -sS https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor > /usr/share/keyrings/conda-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" > /etc/apt/sources.list.d/conda.list
    apt-get update -y

    CONDA_PKG="conda=${VERSION}-0"
    if [ "${VERSION}" = "latest" ]; then
        CONDA_PKG="conda"
    fi

    check_packages $CONDA_PKG

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
