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

JAVA_VERSION="${VERSION:-"latest"}"
INSTALL_GRADLE="${INSTALLGRADLE:-"false"}"
GRADLE_VERSION="${GRADLEVERSION:-"latest"}"
INSTALL_MAVEN="${INSTALLMAVEN:-"false"}"
MAVEN_VERSION="${MAVENVERSION:-"latest"}"
INSTALL_ANT="${INSTALLANT:-"false"}"
ANT_VERSION="${ANTVERSION:-"latest"}"
INSTALL_GROOVY="${INSTALLGROOVY:-"false"}"
GROOVY_VERSION="${GROOVYVERSION:-"latest"}"
JDK_DISTRO="${JDKDISTRO:-"ms"}"

export SDKMAN_DIR="${SDKMAN_DIR:-"/usr/local/sdkman"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# Comma-separated list of java versions to be installed
# alongside JAVA_VERSION, but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
MAJOR_VERSION_ID=$(echo ${VERSION_ID} | cut -d . -f 1)
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    if [[ "${ID}" = "rhel" ]] || [[ "${ID}" = *"alma"* ]] || [[ "${ID}" = *"rocky"* ]]; then
        VERSION_CODENAME="rhel${MAJOR_VERSION_ID}"
    else
        VERSION_CODENAME="${ID}${MAJOR_VERSION_ID}"
    fi
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

if [ "${ADJUSTED_ID}" = "rhel" ] && [ "${VERSION_CODENAME-}" = "centos7" ]; then
    # As of 1 July 2024, mirrorlist.centos.org no longer exists.
    # Update the repo files to reference vault.centos.org.
    sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
    sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
    sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
fi

# Setup INSTALL_CMD & PKG_MGR_CMD
if type apt-get > /dev/null 2>&1; then
    PKG_MGR_CMD=apt-get
    INSTALL_CMD="${PKG_MGR_CMD} -y install --no-install-recommends"
elif type microdnf > /dev/null 2>&1; then
    PKG_MGR_CMD=microdnf
    INSTALL_CMD="${PKG_MGR_CMD} -y install --refresh --best --nodocs --noplugins --setopt=install_weak_deps=0"
elif type dnf > /dev/null 2>&1; then
    PKG_MGR_CMD=dnf
    INSTALL_CMD="${PKG_MGR_CMD} -y install"
elif type yum > /dev/null 2>&1; then
    PKG_MGR_CMD=yum
    INSTALL_CMD="${PKG_MGR_CMD} -y install"
else
    echo "(Error) Unable to find a supported package manager."
    exit 1
fi

# Clean up
clean_up() {
    local pkg
    case ${ADJUSTED_ID} in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        rhel)
            for pkg in epel-release epel-release-latest packages-microsoft-prod; do
                ${PKG_MGR_CMD} -y remove $pkg 2>/dev/null || /bin/true
            done
            rm -rf /var/cache/dnf/* /var/cache/yum/*
            rm -f /etc/yum.repos.d/docker-ce.repo
            ;;
    esac
}
clean_up

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
    local _bashrc
    local _zshrc
    if [ "${UPDATE_RC}" = "true" ]; then
        case $ADJUSTED_ID in
            debian)
                _bashrc=/etc/bash.bashrc
                _zshrc=/etc/zsh/zshrc
                ;;
            rhel)
                _bashrc=/etc/bashrc
                _zshrc=/etc/zshrc
            ;;
        esac
        echo "Updating ${_bashrc} and ${_zshrc}..."
        if [[ "$(cat ${_bashrc})" != *"$1"* ]]; then
            echo -e "$1" >> "${_bashrc}"
        fi
        if [ -f "${_zshrc}" ] && [[ "$(cat ${_zshrc})" != *"$1"* ]]; then
            echo -e "$1" >> "${_zshrc}"
        fi
    fi
}


pkg_manager_update() {
    case $ADJUSTED_ID in
        debian)
            if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
                echo "Running apt-get update..."
                ${PKG_MGR_CMD} update -y
            fi
            ;;
        rhel)
            if [ ${PKG_MGR_CMD} = "microdnf" ]; then
                if [ "$(ls /var/cache/yum/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} makecache ..."
                    ${PKG_MGR_CMD} makecache
                fi
            else
                if [ "$(ls /var/cache/${PKG_MGR_CMD}/* 2>/dev/null | wc -l)" = 0 ]; then
                    echo "Running ${PKG_MGR_CMD} check-update ..."
                    set +e
                        stderr_messages=$(${PKG_MGR_CMD} -q check-update 2>&1)
                        rc=$?
                        # centos 7 sometimes returns a status of 100 when it apears to work.
                        if [ $rc != 0 ] && [ $rc != 100 ]; then
                            echo "(Error) ${PKG_MGR_CMD} check-update produced the following error message(s):"
                            echo "${stderr_messages}"
                            exit 1
                        fi
                    set -e
                fi
            fi
            ;;
    esac
}

# Checks if packages are installed and installs them if not
check_packages() {
    case ${ADJUSTED_ID} in
        debian)
            if ! dpkg -s "$@" > /dev/null 2>&1; then
                pkg_manager_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
        rhel)
            if ! rpm -q "$@" > /dev/null 2>&1; then
                pkg_manager_update
                ${INSTALL_CMD} "$@"
            fi
            ;;
    esac
}

# Use Microsoft JDK for everything but JDK 8 and 18 (unless specified differently with jdkDistro option)
get_jdk_distro() {
    VERSION="$1"
    if [ "${JDK_DISTRO}" = "ms" ]; then
        if echo "${VERSION}" | grep -E '^8([\s\.]|$)' > /dev/null 2>&1 || echo "${VERSION}" | grep -E '^18([\s\.]|$)' > /dev/null 2>&1; then
            JDK_DISTRO="tem"
        fi
    fi
}

find_version_list() {
    prefix="$1"
    suffix="$2"
    install_type=$3
    ifLts="$4"
    version_list=$5
    if [ "${ifLts}" = "true" ]; then 
        all_lts_versions=$(curl -s https://api.adoptium.net/v3/info/available_releases)
        major_version=$(echo "$all_lts_versions" | jq -r '.most_recent_lts')
        regex="${prefix}\\K${major_version}\\.?[0-9]*\\.?[0-9]*${suffix}"
    else 
        regex="${prefix}\\K[0-9]+\\.?[0-9]*\\.?[0-9]*${suffix}"
    fi
    declare -g ${version_list}="$(su ${USERNAME} -c ". \${SDKMAN_DIR}/bin/sdkman-init.sh && sdk list ${install_type} 2>&1 | grep -oP \"${regex}\" | tr -d ' ' | sort -rV")"
}

# Use SDKMAN to install something using a partial version match
sdk_install() {
    local install_type=$1
    local requested_version=$2
    local prefix=$3
    local suffix="${4:-"\\s*"}"
    local full_version_check=${5:-".*-[a-z]+"}
    local set_as_default=${6:-"true"}
    pkgs=("maven" "gradle" "ant" "groovy")
    pkg_vals="${pkgs[@]}"
    if [ "${requested_version}" = "none" ]; then return; fi
    if [ "${requested_version}" = "default" ]; then
        requested_version=""
    elif [[ "${pkg_vals}" =~ "${install_type}" ]] && [ "${requested_version}" = "latest" ]; then
        requested_version=""
    elif [ "${requested_version}" = "lts" ]; then
            check_packages jq
            find_version_list "$prefix" "$suffix" "$install_type" "true" version_list
            requested_version="$(echo "${version_list}" | head -n 1)"
    elif echo "${requested_version}" | grep -oE "${full_version_check}" > /dev/null 2>&1; then
        echo "${requested_version}"
    else 
        find_version_list "$prefix" "$suffix" "$install_type" "false" version_list
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ]; then
            requested_version="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            requested_version="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|-|$)")"
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

# Install dependencies,
check_packages ca-certificates zip unzip sed findutils util-linux tar
# Make sure passwd (Debian) and shadow-utils RHEL family is installed
if [ ${ADJUSTED_ID} = "debian" ]; then
    check_packages passwd
elif [ ${ADJUSTED_ID} = "rhel" ]; then
    check_packages shadow-utils
fi
# minimal RHEL installs may not include curl, or includes curl-minimal instead.
# Install curl if the "curl" command is not present.
if ! type curl > /dev/null 2>&1; then
    check_packages curl
fi

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
sdk_install java ${JAVA_VERSION} "\\s*" "(\\.[a-z0-9]+)*-${JDK_DISTRO}\\s*" ".*-[a-z]+$" "true"

# Additional java versions to be installed but not be set as default.
if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
    OLDIFS=$IFS
    IFS=","
        read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
        for version in "${additional_versions[@]}"; do
            get_jdk_distro ${version}
            sdk_install java ${version} "\\s*" "(\\.[a-z0-9]+)*-${JDK_DISTRO}\\s*" ".*-[a-z]+$" "false"
        done
    IFS=$OLDIFS
    su ${USERNAME} -c ". ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk default java ${JAVA_VERSION}"
fi

# Install Ant
if [[ "${INSTALL_ANT}" = "true" ]] && ! ant -version > /dev/null 2>&1; then
    sdk_install ant ${ANT_VERSION}
fi

# Install Gradle
if [[ "${INSTALL_GRADLE}" = "true" ]] && ! gradle --version > /dev/null 2>&1; then
    sdk_install gradle ${GRADLE_VERSION}
fi

# Install Maven
if [[ "${INSTALL_MAVEN}" = "true" ]] && ! mvn --version > /dev/null 2>&1; then
    sdk_install maven ${MAVEN_VERSION}
fi

# Install Groovy
if [[ "${INSTALL_GROOVY}" = "true" ]] && ! groovy --version > /dev/null 2>&1; then
    sdk_install groovy "${GROOVY_VERSION}"
fi

# Clean up
clean_up

echo "Done!"
