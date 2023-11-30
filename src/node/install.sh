#!/bin/bash
#-------------------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://github.com/devcontainers/features/blob/main/LICENSE for license information.
#-------------------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/devcontainers/features/tree/main/src/node
# Maintainer: The Dev Container spec maintainers

export NODE_VERSION="${VERSION:-"lts"}"
export NVM_VERSION="${NVMVERSION:-"latest"}"
export NVM_DIR="${NVMINSTALLPATH:-"/usr/local/share/nvm"}"
INSTALL_TOOLS_FOR_NODE_GYP="${NODEGYPDEPENDENCIES:-true}"

# Comma-separated list of node versions to be installed (with nvm)
# alongside NODE_VERSION, but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

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

apt_get_update() {
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

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release
if [[ "bionic" = *"${VERSION_CODENAME}"* ]]; then
    if [[ "${NODE_VERSION}" =~ "18" ]] || [[ "${NODE_VERSION}" = "lts" ]]; then
        echo "(!) Unsupported distribution version '${VERSION_CODENAME}' for Node 18. Details: https://github.com/nodejs/node/issues/42351#issuecomment-1068424442"
        exit 1
    fi
fi

# Install dependencies
check_packages apt-transport-https curl ca-certificates tar gnupg2 dirmngr

if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Install yarn
if type yarn > /dev/null 2>&1; then
    echo "Yarn already installed."
else
    # Import key safely (new method rather than deprecated apt-key approach) and install
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor > /usr/share/keyrings/yarn-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/yarn-archive-keyring.gpg] https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
    apt-get update
    apt-get -y install --no-install-recommends yarn
fi

# Adjust node version if required
if [ "${NODE_VERSION}" = "none" ]; then
    export NODE_VERSION=
elif [ "${NODE_VERSION}" = "lts" ]; then
    export NODE_VERSION="lts/*"
elif [ "${NODE_VERSION}" = "latest" ]; then
    export NODE_VERSION="node"
fi

find_version_from_git_tags NVM_VERSION "https://github.com/nvm-sh/nvm"

# Install snipppet that we will run as the user
nvm_install_snippet="$(cat << EOF
set -e
umask 0002
# Do not update profile - we'll do this manually
export PROFILE=/dev/null
curl -so- "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash
source "${NVM_DIR}/nvm.sh"
if [ "${NODE_VERSION}" != "" ]; then
    nvm alias default "${NODE_VERSION}"
fi
EOF
)"

# Snippet that should be added into rc / profiles
nvm_rc_snippet="$(cat << EOF
export NVM_DIR="${NVM_DIR}"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && . "\$NVM_DIR/bash_completion"
EOF
)"

# Create a symlink to the installed version for use in Dockerfile PATH statements
export NVM_SYMLINK_CURRENT=true

# Create nvm group to the user's UID or GID to change while still allowing access to nvm
if ! cat /etc/group | grep -e "^nvm:" > /dev/null 2>&1; then
    groupadd -r nvm
fi
usermod -a -G nvm ${USERNAME}

# Install nvm (which also installs NODE_VERSION), otherwise
# use nvm to install the specified node version. Always use
# umask 0002 so both the owner so that everything is u+rw,g+rw
umask 0002
if [ ! -d "${NVM_DIR}" ]; then
    # Create nvm dir, and set sticky bit
    mkdir -p "${NVM_DIR}"
    chown "${USERNAME}:nvm" "${NVM_DIR}"
    chmod g+rws "${NVM_DIR}"
    su ${USERNAME} -c "${nvm_install_snippet}" 2>&1
    # Update rc files
    if [ "${UPDATE_RC}" = "true" ]; then
        updaterc "${nvm_rc_snippet}"
    fi
else
    echo "NVM already installed."
    if [ "${NODE_VERSION}" != "" ]; then
        su ${USERNAME} -c "umask 0002 && . '$NVM_DIR/nvm.sh' && nvm install '${NODE_VERSION}' && nvm alias default '${NODE_VERSION}'"
    fi
fi

# Additional node versions to be installed but not be set as
# default we can assume the nvm is the group owner of the nvm
# directory and the sticky bit on directories so any installed
# files will have will have the correct ownership (nvm)
if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
    OLDIFS=$IFS
    IFS=","
        read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
        for ver in "${additional_versions[@]}"; do
            su ${USERNAME} -c "umask 0002 && . '$NVM_DIR/nvm.sh' && nvm install '${ver}'"
        done

        # Ensure $NODE_VERSION is on the $PATH
        if [ "${NODE_VERSION}" != "" ]; then
                su ${USERNAME} -c "umask 0002 && . '$NVM_DIR/nvm.sh' && nvm use default"
        fi
    IFS=$OLDIFS
fi

# Install pnpm
if type pnpm > /dev/null 2>&1; then
    echo "pnpm already installed."
else
    if type npm > /dev/null 2>&1; then
        [ ! -z "$http_proxy" ] && npm set proxy="$http_proxy"
        [ ! -z "$https_proxy" ] && npm set https-proxy="$https_proxy"
        [ ! -z "$no_proxy" ] && npm set noproxy="$no_proxy"
        npm install -g pnpm
        pnpm setup
    else
        echo "Skip installing pnpm because npm is missing"
    fi
fi

# If enabled, verify "python3", "make", "gcc", "g++" commands are available so node-gyp works - https://github.com/nodejs/node-gyp
if [ "${INSTALL_TOOLS_FOR_NODE_GYP}" = "true" ]; then
    echo "Verifying node-gyp OS requirements..."
    to_install=""
    if ! type make > /dev/null 2>&1; then
        to_install="${to_install} make"
    fi
    if ! type gcc > /dev/null 2>&1; then
        to_install="${to_install} gcc"
    fi
    if ! type g++ > /dev/null 2>&1; then
        to_install="${to_install} g++"
    fi
    if ! type python3 > /dev/null 2>&1; then
        to_install="${to_install} python3-minimal"
    fi
    if [ ! -z "${to_install}" ]; then
        apt_get_update
        apt-get -y install ${to_install}
    fi
fi


# Clean up
su ${USERNAME} -c "umask 0002 && . '$NVM_DIR/nvm.sh' && nvm clear-cache"
rm -rf /var/lib/apt/lists/*

# Ensure privs are correct for installed node versions. Unfortunately the
# way nvm installs node versions pulls privs from the tar which does not
# have group write set. We need this when the gid/uid is updated.
mkdir -p "${NVM_DIR}/versions"
chmod -R g+rw "${NVM_DIR}/versions"

echo "Done!"
