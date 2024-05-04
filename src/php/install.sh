#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Maintainer: The VS Code and Codespaces Teams

set -eux

# Clean up
rm -rf /var/lib/apt/lists/*

PHP_VERSION="${VERSION:-"latest"}"
INSTALL_COMPOSER="${INSTALLCOMPOSER:-"true"}"
OVERRIDE_DEFAULT_VERSION="${OVERRIDEDEFAULTVERSION:-"true"}"

export PHP_DIR="${PHP_DIR:-"/usr/local/php"}"
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# Comma-separated list of php versions to be installed
# alongside PHP_VERSION, but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

export DEBIAN_FRONTEND=noninteractive

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi


# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

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
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ]; then
    USERNAME=root
    USER_UID=0
    USER_GID=0
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

# Figure out correct version of a three part version number is not passed
find_version_from_git_tags() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    local prefix=${3:-"tags/v"}
    local separator=${4:-"."}
    local last_part_optional=${5:-"false"}    
    echo "${!variable_name}"
    echo "$(echo "${requested_version}" | grep -o "." | wc -l)"
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
    echo "${!variable_name}"
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" > /dev/null 2>&1; then
        echo -e "Invalid ${variable_name} value: ${requested_version}\nValid values:\n${version_list}" >&2
        exit 1
    fi
    echo "${variable_name}=${!variable_name}"
}

# Use semver logic to decrement a version number then look for the closest match
find_prev_version_from_git_tags() {
    local variable_name=$1
    local current_version=${!variable_name}
    local repository=$2
    # Normally a "v" is used before the version number, but support alternate cases
    local prefix=${3:-"tags/v"}
    # Some repositories use "_" instead of "." for version number part separation, support that
    local separator=${4:-"."}
    # Some tools release versions that omit the last digit (e.g. go)
    local last_part_optional=${5:-"false"}
    # Some repositories may have tags that include a suffix (e.g. actions/node-versions)
    # Try one break fix version number less if we get a failure. Use "set +e" since "set -e" can cause failures in valid scenarios.
    set +e
        major="$(echo "${current_version}" | grep -oE '^[0-9]+' || echo '')"
        minor="$(echo "${current_version}" | grep -oP '^[0-9]+\.\K[0-9]+' || echo '')"
        breakfix="$(echo "${current_version}" | grep -oP '^[0-9]+\.[0-9]+\.\K[0-9]+' 2>/dev/null || echo '')"

        if [ "${minor}" = "0" ] && [ "${breakfix}" = "0" ]; then
            ((major=major-1))
            declare -g ${variable_name}="${major}"
            # Look for latest version from previous major release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        # Handle situations like Go's odd version pattern where "0" releases omit the last part
        elif [ "${breakfix}" = "" ] || [ "${breakfix}" = "0" ]; then
            ((minor=minor-1))
            declare -g ${variable_name}="${major}.${minor}"
            # Look for latest version from previous minor release
            find_version_from_git_tags "${variable_name}" "${repository}" "${prefix}" "${separator}" "${last_part_optional}"
        else
            ((breakfix=breakfix-1))
            if [ "${breakfix}" = "0" ] && [ "${last_part_optional}" = "true" ]; then
                declare -g ${variable_name}="${major}.${minor}"
            else 
                declare -g ${variable_name}="${major}.${minor}.${breakfix}"
            fi
        fi
    set -e
}

# Install PHP Composer
addcomposer() {
    "${PHP_SRC}" -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    "${PHP_SRC}" -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    "${PHP_SRC}" composer-setup.php --install-dir="/usr/local/bin" --filename=composer
    "${PHP_SRC}" -r "unlink('composer-setup.php');"
}

init_php_install() {
    PHP_INSTALL_DIR="${PHP_DIR}/${PHP_VERSION}"
    if [ -d "${PHP_INSTALL_DIR}" ]; then
        echo "(!) PHP version ${PHP_VERSION} already exists."
        exit 1
    fi

    if ! cat /etc/group | grep -e "^php:" > /dev/null 2>&1; then
        groupadd -r php
    fi
    usermod -a -G php "${USERNAME}"
    PHP_URL="https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz"

    PHP_INI_DIR="${PHP_INSTALL_DIR}/ini"
    CONF_DIR="${PHP_INI_DIR}/conf.d"
    mkdir -p "${CONF_DIR}";

    PHP_EXT_DIR="${PHP_INSTALL_DIR}/extensions"
    mkdir -p "${PHP_EXT_DIR}"

    PHP_SRC_DIR="/usr/src/php"
    mkdir -p $PHP_SRC_DIR
    cd $PHP_SRC_DIR
}

install_previous_version() {
    PHP_VERSION=$1
    if [[ "$ORIGINAL_PHP_VERSION" == "latest" ]]; then
        find_prev_version_from_git_tags PHP_VERSION https://github.com/php/php-src "tags/php-"
        echo -e "\nAttempting to install previous version v${PHP_VERSION}"
        init_php_install
        wget -O php.tar.xz "$PHP_URL"
    else 
        echo -e "\nFailed to install v$PHP_VERSION"
    fi
}

install_php() {
    PHP_VERSION="$1"

    init_php_install
    
    wget -O php.tar.xz "$PHP_URL" || install_previous_version "$PHP_VERSION"

    tar -xf $PHP_SRC_DIR/php.tar.xz -C "$PHP_SRC_DIR" --strip-components=1
    cd $PHP_SRC_DIR;

    # PHP 7.4+, the pecl/pear installers are officially deprecated and are removed in PHP 8+
    # Thus, requiring an explicit "--with-pear"
    IFS="."
    read -a versions <<< "${PHP_VERSION}"
    PHP_MAJOR_VERSION=${versions[0]}
    PHP_MINOR_VERSION=${versions[1]}

    VERSION_CONFIG=""
    if (( $(($PHP_MAJOR_VERSION)) >= 8 )) || (( $(($PHP_MAJOR_VERSION)) == 7 && $(($PHP_MINOR_VERSION)) >= 4 )); then 
        VERSION_CONFIG="--with-pear"
    fi

    ./configure --prefix="${PHP_INSTALL_DIR}" --with-config-file-path="$PHP_INI_DIR" --with-config-file-scan-dir="$CONF_DIR" --enable-option-checking=fatal --with-curl --with-libedit --enable-mbstring --with-openssl --with-zlib --with-password-argon2 --with-sodium=shared "$VERSION_CONFIG" EXTENSION_DIR="$PHP_EXT_DIR";

    make -j "$(nproc)"
    find -type f -name '*.a' -delete
    make install
    find "${PHP_INSTALL_DIR}" -type f -executable -exec strip --strip-all '{}' + || true
    make clean

    cp -v $PHP_SRC_DIR/php.ini-* "$PHP_INI_DIR/";
    cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

    # Install xdebug
    "${PHP_INSTALL_DIR}/bin/pecl" install xdebug
    XDEBUG_INI="${CONF_DIR}/xdebug.ini"

    echo "zend_extension=${PHP_EXT_DIR}/xdebug.so" > "${XDEBUG_INI}"
    echo "xdebug.mode = debug" >> "${XDEBUG_INI}"
    echo "xdebug.start_with_request = yes" >> "${XDEBUG_INI}"
    echo "xdebug.client_port = 9003" >> "${XDEBUG_INI}"
}

if [ "${PHP_VERSION}" != "none" ]; then
    # Persistent / runtime dependencies
    RUNTIME_DEPS="wget ca-certificates git build-essential xz-utils curl"

    # PHP dependencies
    PHP_DEPS="libssl-dev libcurl4-openssl-dev libedit-dev libsqlite3-dev libxml2-dev zlib1g-dev libsodium-dev libonig-dev"

    . /etc/os-release

    if [ "${VERSION_CODENAME}" = "bionic" ]; then
        PHP_DEPS="${PHP_DEPS} libargon2-0-dev"
    else
        PHP_DEPS="${PHP_DEPS} libargon2-dev"
    fi

    # Dependencies required for running "phpize"
    PHPIZE_DEPS="autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c"

    # Install dependencies
    check_packages $RUNTIME_DEPS $PHP_DEPS $PHPIZE_DEPS

    # storing value of PHP_VERSION before it changes
    ORIGINAL_PHP_VERSION=$PHP_VERSION
    find_version_from_git_tags PHP_VERSION https://github.com/php/php-src "tags/php-"
    install_php "${PHP_VERSION}"

    PHP_SRC="${PHP_INSTALL_DIR}/bin/php"
else
    set +e
        PHP_SRC=$(which php)
    set -e
fi

# Install PHP Composer if needed
if [[ "${INSTALL_COMPOSER}" = "true" ]]; then
    if [ -z "${PHP_SRC}" ]; then
        echo "(!) Could not install Composer. PHP not found."
        exit 1
    fi

    addcomposer
fi

# Additional php versions to be installed but not be set as default.
if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
    OLDIFS=$IFS
    IFS=","
        read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
        for version in "${additional_versions[@]}"; do
            OVERRIDE_DEFAULT_VERSION="false"
            install_php "${version}"
        done
    IFS=$OLDIFS
fi

if [ "${PHP_VERSION}" != "none" ]; then
    CURRENT_DIR="${PHP_DIR}/current"
    if [[ ! -d "${CURRENT_DIR}" ]]; then
        ln -s -r "${PHP_INSTALL_DIR}" ${CURRENT_DIR}
    fi

    if [ "${OVERRIDE_DEFAULT_VERSION}" = "true" ]; then
        if [[ $(ls -l ${CURRENT_DIR}) != *"-> ${PHP_INSTALL_DIR}"* ]] ; then
            rm "${CURRENT_DIR}"
            ln -s -r "${PHP_INSTALL_DIR}" "${CURRENT_DIR}"
        fi
    fi

    rm -rf "${PHP_SRC_DIR}"
    updaterc "if [[ \"\${PATH}\" != *\"${CURRENT_DIR}\"* ]]; then export PATH=\"${CURRENT_DIR}/bin:\${PATH}\"; fi"

    chown -R "${USERNAME}:php" "${PHP_DIR}"
    chmod -R g+r+w "${PHP_DIR}"
    find "${PHP_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
