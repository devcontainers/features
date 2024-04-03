#!/bin/bash

echo -e "\nInstalled PHP Version by Feature: 👇 "; php -v;

USERNAME="root"
PHP_DIR="/usr/local/php"

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
    echo -e "\nInstalling Previous Version..."
    find_prev_version_from_git_tags PHP_VERSION https://github.com/php/php-src "tags/php-"
    echo -e "\nNow installing this version as a fallback previous version: ${PHP_VERSION} 🤞🏻"
    init_php_install
    wget -O php.tar.xz "$PHP_URL"
}

install_php() {  
    # trying to install with a possible new tag not having a released source binary yet
    PHP_VERSION="8.3.xyz"

    init_php_install

    wget -O php.tar.xz "$PHP_URL" || install_previous_version
    
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

apt-get purge php.*
PHP_DIR="/usr/local/php"
PHP_INSTALL_DIR="${PHP_DIR}/${PHP_VERSION}"
PHP_SRC_DIR="/usr/src/php"

install_php
PHP_SRC="${PHP_INSTALL_DIR}/bin/php"

updaterc() {
    echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."
    if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/bash.bashrc
    fi
    if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"$1"* ]]; then
        echo -e "$1" >> /etc/zsh/zshrc
    fi
}

if [ "${PHP_VERSION}" != "none" ]; then
    CURRENT_DIR="${PHP_DIR}/current"
    if [[ ! -d "${CURRENT_DIR}" ]]; then
        ln -s -r "${PHP_INSTALL_DIR}" ${CURRENT_DIR}
    fi

    if [[ $(ls -l ${CURRENT_DIR}) != *"-> ${PHP_INSTALL_DIR}"* ]] ; then
        rm "${CURRENT_DIR}"
        ln -s -r "${PHP_INSTALL_DIR}" "${CURRENT_DIR}"
    fi

    rm -rf "${PHP_SRC_DIR}"
    updaterc "if [[ \"\${PATH}\" != *\"${CURRENT_DIR}\"* ]]; then export PATH=\"${CURRENT_DIR}/bin:\${PATH}\"; fi"

    chown -R "${USERNAME}:php" "${PHP_DIR}"
    chmod -R g+r+w "${PHP_DIR}"
    find "${PHP_DIR}" -type d -print0 | xargs -n 1 -0 chmod g+s
fi

echo -e "\nInstalled PHP Version by Test: 👇 "; php -v;

