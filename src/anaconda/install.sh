#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/anaconda.md
# Maintainer: The VS Code and Codespaces Teams


VERSION="${VERSION:-"latest"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"
CONDA_DIR="${CONDA_DIR:-"/usr/local/conda"}"

set -exo pipefail
export DEBIAN_FRONTEND=noninteractive

# Detect package manager and set install command
detect_package_manager() {
    if command -v apt-get > /dev/null; then
        PKG_MANAGER="apt-get"
        PKG_UPDATE="apt-get update -y"
        PKG_INSTALL="apt-get -y install --no-install-recommends"
        PKG_CLEAN="apt-get -y clean"
        PKG_LISTS="/var/lib/apt/lists/*"
        PKG_QUERY="dpkg -s"
    elif command -v apk > /dev/null; then
        PKG_MANAGER="apk"
        PKG_UPDATE="apk update"
        PKG_INSTALL="apk add --no-cache"
        PKG_CLEAN="rm -rf /var/cache/apk/*"
        PKG_LISTS="/var/cache/apk/*"
        PKG_QUERY="apk info -e"
    elif command -v dnf > /dev/null; then
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf -y makecache"
        PKG_INSTALL="dnf -y install"
        PKG_CLEAN="dnf clean all"
        PKG_LISTS="/var/cache/dnf/*"
        PKG_QUERY="rpm -q"
    elif command -v microdnf > /dev/null; then
        PKG_MANAGER="microdnf"
        PKG_UPDATE="microdnf update"
        PKG_INSTALL="microdnf install -y"
        PKG_CLEAN="microdnf clean all"
        PKG_LISTS="/var/cache/yum/*"
        PKG_QUERY="rpm -q"
    elif command -v tdnf > /dev/null; then
        PKG_MANAGER="tdnf"
        PKG_UPDATE="tdnf makecache"
        PKG_INSTALL="tdnf install -y"
        PKG_CLEAN="tdnf clean all"
        PKG_LISTS="/var/cache/tdnf/*"
        PKG_QUERY="rpm -q"
    elif command -v yum > /dev/null; then
        PKG_MANAGER="yum"
        PKG_UPDATE="yum -y makecache"
        PKG_INSTALL="yum -y install"
        PKG_CLEAN="yum clean all"
        PKG_LISTS="/var/cache/yum/*"
        PKG_QUERY="rpm -q"
    else
        echo "No supported package manager found (apt-get, apk, dnf, microdnf, tdnf, yum)."
        exit 1
    fi
}

detect_package_manager

# Clean up
rm -rf $PKG_LISTS 

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
# Normalize arm64 to aarch64 for consistency
if [ "${architecture}" = "arm64" ]; then
    architecture="aarch64"
fi

if [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "aarch64" ]; then
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
    for pkg in "$@"; do
        if [ "$PKG_MANAGER" = "apt-get" ]; then
            if ! dpkg -s "$pkg" > /dev/null 2>&1; then
                if [ "$(find $PKG_LISTS | wc -l)" = "0" ]; then
                    echo "Running $PKG_UPDATE..."
                    eval "$PKG_UPDATE"
                fi
                eval "$PKG_INSTALL $pkg"
            fi
        elif [ "$PKG_MANAGER" = "apk" ]; then
            if ! apk info -e "$pkg" > /dev/null 2>&1; then
                echo "Running $PKG_UPDATE..."
                eval "$PKG_UPDATE"
                eval "$PKG_INSTALL $pkg"
            fi
        else
            if ! rpm -q "$pkg" > /dev/null 2>&1; then
                echo "Running $PKG_UPDATE..."
                eval "$PKG_UPDATE"
                eval "$PKG_INSTALL $pkg"
            fi
        fi
    done
}

sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        if command -v runuser > /dev/null; then
            runuser -l "$USERNAME" -c "$COMMAND"
        elif command -v su > /dev/null; then
            su - "$USERNAME" -c "$COMMAND"
        elif command -v sudo > /dev/null; then
            sudo -u "$USERNAME" -i bash -c "$COMMAND"
        else
            # Fallback: execute as root (not ideal but works in containers)
            echo "Warning: No user switching command available, running as root"
            eval "$COMMAND"
        fi
    else
        eval "$COMMAND"
    fi
}

install_user_package() {
    PACKAGE="$1"
    sudo_if "${CONDA_DIR}/bin/python3" -m pip install --user --upgrade "$PACKAGE"
}

run_as_user() {
    local user="$1"
    shift
    local cmd="$*"
    
    if command -v runuser > /dev/null; then
        if [ "$PKG_MANAGER" = "apk" ]; then
            runuser "$user" -c "$cmd"
        else
            runuser -l "$user" -c "$cmd"
        fi
    elif command -v su > /dev/null; then
        if [ "$PKG_MANAGER" = "apk" ]; then
            su "$user" -c "$cmd"
        else
            su --login -c "$cmd" "$user"
        fi
    elif command -v sudo > /dev/null; then
        if [ "$PKG_MANAGER" = "apk" ]; then
            sudo -u "$user" sh -c "$cmd"
        else
            sudo -u "$user" -i bash -c "$cmd"
        fi
    else
        echo "Warning: No user switching command available, running as root"
        eval "$cmd"
    fi
}
# Set permissions for directories recursively
set_directory_permissions() {
    local dir="$1"
    for item in "$dir"/*; do
        if [ -d "$item" ]; then
            chmod g+s "$item"
            set_directory_permissions "$item"
        fi
    done
}

# Install Conda if it's missing
if ! conda --version &> /dev/null ; then
    if ! cat /etc/group | grep -e "^conda:" > /dev/null 2>&1; then
        groupadd -r conda
    fi
    usermod -a -G conda "${USERNAME}"

    # Install dependencies
    if [ "$PKG_MANAGER" = "apt-get" ]; then
        check_packages wget ca-certificates libgtk-3-0
    elif [ "$PKG_MANAGER" = "apk" ]; then
        check_packages wget ca-certificates gtk+3.0
    else
        check_packages wget ca-certificates gtk3
    fi  

    mkdir -p $CONDA_DIR

    chown -R "${USERNAME}:conda" "${CONDA_DIR}"
    chmod -R g+r+w "${CONDA_DIR}"    

    echo "Installing Anaconda..."

    CONDA_VERSION=$VERSION
    if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
        CONDA_VERSION="2024.10-1"
    fi

    if [ "${architecture}" = "x86_64" ]; then
        run_as_user "${USERNAME}" "export http_proxy=${http_proxy:-} && export https_proxy=${https_proxy:-} \
            && wget -q https://repo.anaconda.com/archive/Anaconda3-${CONDA_VERSION}-Linux-x86_64.sh -O /tmp/anaconda-install.sh \
            && /bin/bash /tmp/anaconda-install.sh -u -b -p ${CONDA_DIR}"
    elif [ "${architecture}" = "aarch64" ]; then
        run_as_user "${USERNAME}" "export http_proxy=${http_proxy:-} && export https_proxy=${https_proxy:-} \
            && wget -q https://repo.anaconda.com/archive/Anaconda3-${CONDA_VERSION}-Linux-aarch64.sh -O /tmp/anaconda-install.sh \
            && /bin/bash /tmp/anaconda-install.sh -u -b -p ${CONDA_DIR}"
    fi
    
    if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
        PATH=$PATH:${CONDA_DIR}/bin
        conda update -y conda
    fi

    chown -R "${USERNAME}:conda" "${CONDA_DIR}"
    chmod -R g+r+w "${CONDA_DIR}"    

    # Set setgid bit on all directories - use find+xargs if available, fallback to recursive function
    if command -v find > /dev/null && command -v xargs > /dev/null; then
        find "${CONDA_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s
    else
        # Fallback for systems without find or xargs
        if [ -d "${CONDA_DIR}" ]; then
            chmod g+s "${CONDA_DIR}"  
            set_directory_permissions "${CONDA_DIR}"
        fi
    fi

    # Temporary fixes
    # Due to https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-23491
    install_user_package certifi
    # Due to https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-0286 and https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2023-23931
    install_user_package pyopenssl
    install_user_package cryptography
    # Due to https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2022-40897
    install_user_package setuptools
    install_user_package tornado

    rm /tmp/anaconda-install.sh
    updaterc "export CONDA_DIR=${CONDA_DIR}/bin"
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

# Final clean up
eval "$PKG_CLEAN"
rm -rf $PKG_LISTS

echo "Done!"
