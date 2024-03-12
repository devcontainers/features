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

install_previous_version() {
    echo -e "\nInstalling Previous Version..."
    PHP_VERSION=$1
    find_prev_version_from_git_tags PHP_VERSION https://github.com/php/php-src "tags/php-"
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
    wget -O php.tar.xz "$PHP_URL"
    ln -sf /usr/local/php/8.1.27 /usr/local/php/current
    echo 'export PATH=/usr/local/php/current/bin:$PATH' >> ~/.bashrc
    . ~/.bashrc
}

install_php() {  
    apt-get remove –purge php*
    apt-get purge php*
    apt-get autoremove
    apt-get autoclean
    apt-get remove dbconfig-php
    apt-get dist-upgrade
    # whereis php | while IFS= read -r line; do
    #     # Remove leading and trailing whitespace from the line
    #     line=$(echo "$line" | awk '{$1=$1};1')
    #     # Check if the line is not empty
    #     if [ -n "$line" ]; then
    #         # Delete the file or directory
    #         echo "Deleting: $line"
    #         rm -rf "$line"
    #     fi
    # done
    rm /usr/local/php/current

    # trying to install a non existent fake binary for a possibly new tag which doesn't have a release yet
    PHP_VERSION="v1.2.xyz"
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

    wget -O php.tar.xz "$PHP_URL" || install_previous_version "8.2"
    tar -xf $PHP_SRC_DIR/php.tar.xz -C "$PHP_SRC_DIR"
}

install_php

echo -e "\nInstalled PHP Version by Test: 👇 "; php -v;

