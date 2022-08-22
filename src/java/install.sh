#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/java.md
# Maintainer: The VS Code and Codespaces Teams
#
# Syntax: ./java-debian.sh [JDK version] [SDKMAN_DIR] [non-root user] [Add to rc files flag]

JAVA_VERSION=${VERSION:-"lts"}
INSTALL_GRADLE=${INSTALLGRADLE:-"false"}
INSTALL_MAVEN=${INSTALLMAVEN:-"false"}

export SDKMAN_DIR=${SDKMAN_DIR:-"/usr/local/sdkman"}
USERNAME=${USERNAME:-"automatic"}
UPDATE_RC=${UPDATE_RC:-"true"}

# Comma-separated list of java versions to be installed
# alongside JAVA_VERSION, but not set as default.
ADDITIONAL_VERSIONS=${ADDITIONALVERSIONS:-""}

set -e

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

# Use Microsoft JDK for everything but JDK 8
jdk_distro="ms"
get_jdk_distro() {
    VERSION="$1"
    if echo "${VERSION}" | grep -E '^8([\s\.]|$)' > /dev/null 2>&1; then
        jdk_distro="tem"
    fi
}

# Use SDKMAN to install something using a partial version match
sdk_install() {
    local install_type=$1
    local requested_version=$2
    local prefix=$3
    local suffix="${4:-"\\s*"}"
    local full_version_check=${5:-".*-[a-z]+"}
    local set_as_default=${6:-"true"}
    if [ "${requested_version}" = "none" ]; then return; fi
    # Blank will install latest stable version SDKMAN has
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "default" ]; then
         requested_version=""
    elif echo "${requested_version}" | grep -oE "${full_version_check}" > /dev/null 2>&1; then
        echo "${requested_version}"
    else
        local regex="${prefix}\\K[0-9]+\\.[0-9]+\\.[0-9]+${suffix}"
        local version_list=$(su ${USERNAME} -c ". \${SDKMAN_DIR}/bin/sdkman-init.sh && sdk list ${install_type} 2>&1 | grep -oP \"${regex}\" | tr -d ' ' | sort -rV")
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ]; then
            requested_version="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            requested_version="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
        if [ -z "${requested_version}" ] || ! echo "${version_list}" | grep "^${requested_version//./\\.}$" > /dev/null 2>&1; then
            echo -e "Version $2 not found. Available versions:\n${version_list}" >&2
            exit 1
        fi
    fi
    if [ "${set_as_default}" = "true" ]; then
        JAVA_VERSION=${requested_version}
    fi

    su ${USERNAME} -c "umask 0002 && . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install ${install_type} ${requested_version} && sdk flush archives && sdk flush temp"
}

export DEBIAN_FRONTEND=noninteractive

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

# Install dependencies
check_packages curl ca-certificates zip unzip sed

# Install sdkman if not installed
if [ ! -d "${SDKMAN_DIR}" ]; then
    # Create sdkman group, dir, and set sticky bit
    if ! cat /etc/group | grep -e "^sdkman:" > /dev/null 2>&1; then
        groupadd -r sdkman
    fi
    usermod -a -G sdkman ${USERNAME}
    umask 0002
    # Install SDKMAN
    curl -sSL "https://get.sdkman.io?rcupdate=false" | bash
    chown -R "${USERNAME}:sdkman" ${SDKMAN_DIR}
    find ${SDKMAN_DIR} -type d -print0 | xargs -d '\n' -0 chmod g+s
    # Add sourcing of sdkman into bashrc/zshrc files (unless disabled)
    updaterc "export SDKMAN_DIR=${SDKMAN_DIR}\n. \${SDKMAN_DIR}/bin/sdkman-init.sh"
fi

get_jdk_distro ${JAVA_VERSION}
sdk_install java ${JAVA_VERSION} "\\s*" "(\\.[a-z0-9]+)*-${jdk_distro}\\s*" ".*-[a-z]+$" "true"

# Additional java versions to be installed but not be set as default.
if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
    OLDIFS=$IFS
    IFS=","
        read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
        for version in "${additional_versions[@]}"; do
            get_jdk_distro ${version}
            sdk_install java ${version} "\\s*" "(\\.[a-z0-9]+)*-${jdk_distro}\\s*" ".*-[a-z]+$" "false"
        done
    IFS=$OLDIFS
    su ${USERNAME} -c ". ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk default java ${JAVA_VERSION}"
fi

# Install Gradle
if [[ "${INSTALL_GRADLE}" = "true" ]] && ! gradle --version > /dev/null; then
    sdk_install gradle latest
    updaterc '[ -z "${GRADLE_USER_HOME}" ] && export GRADLE_USER_HOME=${HOME}/.gradle'
fi

# Install Maven
if [[ "${INSTALL_MAVEN}" = "true" ]] && ! mvn --version > /dev/null; then
    sdk_install maven latest
    updaterc '[ -z "$M2" ] && export M2=$HOME/.m2'
fi

echo "Done!"
