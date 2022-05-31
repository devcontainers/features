#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Maintainer: The VS Code and Codespaces Teams
#
# Syntax: ./php-debian.sh [PHP version] [PHP_DIR] [Add Composer flag] [Non-root user] [Add rc files flag]

VERSION=${1:-"latest"}
export PHP_DIR=${2:-"/usr/local/php"}
INSTALL_COMPOSER=${3:-"true"}
USERNAME=${4:-"automatic"}
UPDATE_RC=${5:-"true"}
OVERRIDE_DEFAULT_VERSION=${6:-"true"}

set -eux
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
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
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
        apt-get update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Figure out correct version of PHP
find_version_from_git_tags() {
    local repository="https://github.com/php/php-src"
    local separator="."
    local escaped_separator=${separator//./\\.}
    local last_part="${escaped_separator}[0-9]+"
    local regex="\\K[0-9]+${escaped_separator}[0-9]+${last_part}$"
    local version_list="$(git ls-remote --tags ${repository} | grep -oP "${regex}" | tr -d ' ' | tr "${separator}" "." | sort -rV)"
    VERSION="$(echo "${version_list}" | head -n 1)"
}

# Install PHP Composer
addcomposer() {
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"

    mv composer.phar "${PHP_INSTALL_DIR}/composer"
}

# Install PHP if it's missing


# Persistent / runtime dependencies
RUNTIME_DEPS="wget ca-certificates git build-essential xz-utils"

# PHP dependencies
PHP_DEPS="libssl-dev libcurl4-openssl-dev libedit-dev libsqlite3-dev libxml2-dev zlib1g-dev libsodium-dev libargon2-dev libonig-dev"

# Dependencies required for running "phpize"
PHPIZE_DEPS="autoconf dpkg-dev file g++ gcc libc-dev make pkg-config re2c"

# Install dependencies
check_packages $RUNTIME_DEPS $PHP_DEPS $PHPIZE_DEPS

# Fetch latest version of PHP if needed
if [ "${VERSION}" = "latest" ] || [ "${VERSION}" = "lts" ]; then
    find_version_from_git_tags
fi

PHP_INSTALL_DIR="${PHP_DIR}/${VERSION}"
if [ -d "${PHP_INSTALL_DIR}" ]; then
    echo "(!) PHP version ${VERSION} already exists."
    exit 0
fi

PHP_URL="https://www.php.net/distributions/php-${VERSION}.tar.gz"

PHP_INI_DIR="${PHP_INSTALL_DIR}/ini"
CONF_DIR="$PHP_INI_DIR/conf.d"
mkdir -p $CONF_DIR;

PHP_EXT_DIR="${PHP_INSTALL_DIR}/extensions"
mkdir -p $PHP_EXT_DIR

PHP_SRC_DIR="/usr/src/php"
mkdir -p $PHP_SRC_DIR
cd $PHP_SRC_DIR
wget -O php.tar.xz "$PHP_URL"

tar -xf $PHP_SRC_DIR/php.tar.xz -C "$PHP_SRC_DIR" --strip-components=1
cd $PHP_SRC_DIR;

# PHP 7.4+, the pecl/pear installers are officially deprecated and are removed in PHP 8+
# Thus, requiring an explicit "--with-pear"
IFS="."
read -a versions <<< "$VERSION"
PHP_MAJOR_VERSION=${versions[0]}
PHP_MINOR_VERSION=${versions[1]}

VERSION_CONFIG=""
if (( $(($PHP_MAJOR_VERSION)) >= 8 )) || (( $(($PHP_MAJOR_VERSION)) == 7 && $(($PHP_MINOR_VERSION)) >= 4 )); then 
    VERSION_CONFIG="--with-pear"
fi

./configure --prefix="${PHP_INSTALL_DIR}" --with-config-file-path="$PHP_INI_DIR" --with-config-file-scan-dir="$CONF_DIR" --enable-option-checking=fatal --with-curl --with-libedit --with-openssl --with-zlib --with-password-argon2 --with-sodium=shared "$VERSION_CONFIG" EXTENSION_DIR="$PHP_EXT_DIR";

make -j "$(nproc)"
find -type f -name '*.a' -delete
make install
find "${PHP_INSTALL_DIR}" -type f -executable -exec strip --strip-all '{}' + || true
make clean

cp -v $PHP_SRC_DIR/php.ini-* "$PHP_INI_DIR/";
cp "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

if [ "${OVERRIDE_DEFAULT_VERSION}" = "true" ]; then
    CURRENT_DIR="${PHP_DIR}/current"
    ln -s "${PHP_INSTALL_DIR}" ${CURRENT_DIR}
    export PATH="${PATH}:${CURRENT_DIR}/bin"
fi
PATH="${PATH}:${PHP_INSTALL_DIR}/bin"

# Install xdebug
pecl install xdebug
XDEBUG_INI="$CONF_DIR/xdebug.ini"
echo "zend_extension=$(find $PHP_EXT_DIR -name xdebug.so)" > XDEBUG_INI
echo "xdebug.mode = debug" >> XDEBUG_INI
echo "xdebug.start_with_request = yes" >> XDEBUG_INI
echo "xdebug.client_port = 9003" >> XDEBUG_INI

# Install PHP Composer if needed
if [[ "${INSTALL_COMPOSER}" = "true" ]] && [[ $(composer --version) = "" ]]; then
    addcomposer
fi

rm -rf ${PHP_SRC_DIR}
if [ "${OVERRIDE_DEFAULT_VERSION}" = "true" ]; then
    updaterc "export PHP_DIR=${CURRENT_DIR}/bin"
fi

echo "Done!"
