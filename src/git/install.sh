#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/git-from-src.md
# Maintainer: The VS Code and Codespaces Teams

GIT_VERSION=${VERSION} # 'system' checks the base image first, else installs 'latest'
USE_PPA_IF_AVAILABLE=${PPA}

GIT_CORE_PPA_ARCHIVE_GPG_KEY=E1DD270288B4E6030699E45FA1715D88E1DF1F24
GPG_KEY_SERVERS="keyserver hkp://keyserver.ubuntu.com
keyserver hkp://keyserver.ubuntu.com:80
keyserver hkps://keys.openpgp.org
keyserver hkp://keyserver.pgp.com"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    VERSION_CODENAME="${ID}{$VERSION_ID}"
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

if [ ${ADJUSTED_ID} = "rhel" ]; then
    if type dnf > /dev/null 2>&1; then
        INSTALL_CMD=dnf
    elif type microdnf > /dev/null 2>&1; then
        INSTALL_CMD=microdnf
    else
        INSTALL_CMD=yum
    fi
fi

# Clean up
clean_up() {
    case $ADJUSTED_ID in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        rhel)
            rm -rf /var/cache/dnf/*
            rm -rf /var/cache/yum/*
            ;;
    esac
}
clean_up

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    if [ ! -z "$2" ]; then
        mkdir -p "$(dirname \"$2\")"
        keyring_args="--no-default-keyring --keyring $2"
    fi

    # Use a temporary location for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo -e "disable-ipv6\n${GPG_KEY_SERVERS}" > ${GNUPGHOME}/dirmngr.conf
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; 
    do
        echo "(*) Downloading GPG key..."
        ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retring in 10s..."
            (( retry_count++ ))
            sleep 10s
        fi
    done
    set -e
    if [ "${gpg_ok}" = "false" ]; then
        echo "(!) Failed to get gpg key."
        exit 1
    fi
}

pkg_mgr_update() {
    if type apt >/dev/null 2>&1; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt-get update..."
            apt-get update -y
        fi
    elif [ ${INSTALL_CMD} = "dnf" ] || [ ${INSTALL_CMD} = "yum" ]; then
        if [ "$(find /var/cache/${INSTALL_CMD}/* | wc -l)" = "0" ]; then
            echo "Running ${INSTALL_CMD} check-update ..."
            ${INSTALL_CMD} check-update
        fi
    fi
}


# Checks if packages are installed and installs them if not
check_packages() {
    if type apt >/dev/null 2>&1; then
        if ! dpkg -s "$@" > /dev/null 2>&1; then
            pkg_mgr_update
            apt-get -y install --no-install-recommends "$@"
        fi
    elif [ ${INSTALL_CMD} = "dnf" ] || [ ${INSTALL_CMD} = "yum" ]; then
        _num_pkgs=$(echo "$@" | tr ' ' \\012 | wc -l)
        _num_installed=$(${INSTALL_CMD} -C list installed "$@" | sed '1,/^Installed/d' | wc -l)
        if [ ${_num_pkgs} != ${_num_installed} ]; then
            pkg_mgr_update
            ${INSTALL_CMD} -y install "$@"
        fi
    elif [ ${INSTALL_CMD} = "microdnf" ]; then
        ${INSTALL_CMD} -y install \
            --refresh \
            --best \
            --nodocs \
            --noplugins \
            --setopt=install_weak_deps=0 \
            "$@"
    else
        echo "Linux distro ${ID} not supported."
        exit 1
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Debian / Ubuntu packages

# If the os provided version is "good enough", just install that.
if [ ${GIT_VERSION} = "os-provided" ] || [ ${GIT_VERSION} = "system" ]; then
    if type git > /dev/null 2>&1; then
        echo "Detected existing system install: $(git version)"
        # Clean up
        clean_up
        exit 0
    fi

    echo "Installing git from OS apt/dnf/microdnf/yum repository"
    check_packages git
    # Clean up
    clean_up
    exit 0
fi

# If ubuntu, PPAs allowed, and latest - install from there
if ([ "${GIT_VERSION}" = "latest" ] || [ "${GIT_VERSION}" = "lts" ] || [ "${GIT_VERSION}" = "current" ]) && [ "${ID}" = "ubuntu" ] && [ "${USE_PPA_IF_AVAILABLE}" = "true" ]; then
    echo "Using PPA to install latest git..."
    check_packages apt-transport-https curl ca-certificates gnupg2 dirmngr
    receive_gpg_keys GIT_CORE_PPA_ARCHIVE_GPG_KEY /usr/share/keyrings/gitcoreppa-archive-keyring.gpg
    echo -e "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gitcoreppa-archive-keyring.gpg] http://ppa.launchpad.net/git-core/ppa/ubuntu ${VERSION_CODENAME} main\ndeb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gitcoreppa-archive-keyring.gpg] http://ppa.launchpad.net/git-core/ppa/ubuntu ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/git-core-ppa.list
    apt-get update
    apt-get -y install --no-install-recommends git 
    rm -rf "/tmp/tmp-gnupg"
    rm -rf /var/lib/apt/lists/*
    exit 0
fi

# Install required packages to build if missing
if [ "${ADJUSTED_ID}" = "debian" ]; then

    check_packages build-essential curl ca-certificates tar gettext libssl-dev zlib1g-dev libcurl?-openssl-dev libexpat1-dev

    check_packages libpcre2-dev

    if [ "${VERSION_CODENAME}" = "focal" ] || [ "${VERSION_CODENAME}" = "bullseye" ]; then
        check_packages libpcre2-posix2
    elif [ "${VERSION_CODENAME}" = "bionic" ] || [ "${VERSION_CODENAME}" = "buster" ]; then
        check_packages libpcre2-posix0
    else
        check_packages libpcre2-posix3
    fi

elif [ "${ADJUSTED_ID}" = "rhel" ]; then

    if [ $VERSION_CODENAME = "centos7" ]; then
        check_packages centos-release-scl 
        check_packages devtoolset-11
        source /opt/rh/devtoolset-11/enable
    else
        check_packages gcc
    fi

    check_packages libcurl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel cmake pcre2-devel tar gzip
    if [ $VERSION_ID -lt "9" ]; then
        check_packages curl
    fi
fi

# Partial version matching
if [ "$(echo "${GIT_VERSION}" | grep -o '\.' | wc -l)" != "2" ]; then
    requested_version="${GIT_VERSION}"
    version_list="$(curl -sSL -H "Accept: application/vnd.github.v3+json" "https://api.github.com/repos/git/git/tags" | grep -oP '"name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"' | sort -rV )"
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "current" ]; then
        GIT_VERSION="$(echo "${version_list}" | head -n 1)"
    else
        set +e
        GIT_VERSION="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
        set -e
    fi
    if [ -z "${GIT_VERSION}" ] || ! echo "${version_list}" | grep "^${GIT_VERSION//./\\.}$" > /dev/null 2>&1; then
        echo "Invalid git version: ${requested_version}" >&2
        exit 1
    fi
fi

echo "Downloading source for ${GIT_VERSION}..."
curl -sL https://github.com/git/git/archive/v${GIT_VERSION}.tar.gz | tar -xzC /tmp 2>&1
echo "Building..."
cd /tmp/git-${GIT_VERSION}
make -s USE_LIBPCRE=YesPlease prefix=/usr/local sysconfdir=/etc all && make -s USE_LIBPCRE=YesPlease prefix=/usr/local sysconfdir=/etc install 2>&1
rm -rf /tmp/git-${GIT_VERSION}
clean_up
echo "Done!"
