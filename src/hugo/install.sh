#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/hugo.md
# Maintainer: The VS Code and Codespaces Teams

VERSION=${VERSION:-"latest"}

USERNAME=${USERNAME:-"automatic"}
UPDATE_RC=${UPDATE_RC:-"true"}

HUGO_DIR=${HUGO_DIR:-"/usr/local/hugo"}

set -e

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

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
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

# Install dependencies
check_packages curl ca-certificates tar

# Fetch latest version of Hugo if needed
if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    export VERSION=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
fi

# Install Hugo if it's missing
if ! hugo version &> /dev/null ; then
    if ! cat /etc/group | grep -e "^hugo:" > /dev/null 2>&1; then
        groupadd -r hugo
    fi
    usermod -a -G hugo "${USERNAME}"

    echo "Installing Hugo..."
    installation_dir="$HUGO_DIR/bin"
    mkdir -p "$installation_dir"

    # Install ARM or x86 version of hugo based on current machine architecture
    if [ "$(uname -m)" == "aarch64" ]; then
        arch="ARM64"
    else
        arch="64bit"
    fi

    # Install extended version of hugo if desired
    if [ "${EXTENDED}" = "true" ]; then
        extended="extended_"
    else
        extended=""
    fi

    hugo_filename="hugo_${extended}${VERSION}_Linux-${arch}.tar.gz"

    curl -fsSLO --compressed "https://github.com/gohugoio/hugo/releases/download/v${VERSION}/${hugo_filename}"
    tar -xzf "$hugo_filename" -C "$installation_dir"
    rm "$hugo_filename"

    updaterc "export HUGO_DIR=${installation_dir}"

    chown -R "${USERNAME}:hugo" "${HUGO_DIR}"
    chmod -R g+r+w "${HUGO_DIR}"
    find "${HUGO_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
