#!/bin/bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*


LIQUIBASE_VERSION="${VERSION:-"latest"}"

LIQUIBASE_SHA256="6113f652d06a71556d6ed4a8bb371ab2d843010cb0365379e83df8b4564a6a76"

LIQUIBASE_DIR="${LIQUIBASE_DIR:-"/usr/local/liquibase"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

INSTALL_MONGODB_DRIVER=${INSTALLMONGODRIVER:-false}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Ensure that login shells get the correct path if the user updated the PATH using ENV.
rm -f /etc/profile.d/00-restore-env.sh
echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
chmod +x /etc/profile.d/00-restore-env.sh

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

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install dependencies if missing
check_packages curl ca-certificates tar

#Fetch latest version of Liquibase if needed
if [ "${LIQUIBASE_VERSION}" = "latest" ] || [ "${LIQUIBASE_VERSION}" = "lts" ]; then
    export LIQUIBASE_VERSION=$(curl -s https://api.github.com/repos/liquibase/liquibase/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
fi

# Install Liquibase if it's missing
if ! liquibase --version &> /dev/null ; then
    installation_dir="$LIQUIBASE_DIR"
    mkdir -p "$installation_dir"
    
    liquibase_filename="liquibase-${LIQUIBASE_VERSION}.tar.gz"

    echo "Download Liquibase..."
    curl -fsSLO --compressed "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/${liquibase_filename}"

    if [ "${LIQUIBASE_SHA256}" != "dev-mode" ]; then
        echo "Check Liquibase SHA256..."
        echo "${LIQUIBASE_SHA256}  ${liquibase_filename}" | sha256sum -c
    fi

    tar -xzf "$liquibase_filename" -C "$installation_dir"
    rm "$liquibase_filename"
    
    updaterc "export LIQUIBASE_HOME=${installation_dir}"
fi

# Drivers
if [ "${INSTALL_MONGODB_DRIVER}" = "true" ]; then
    mongodb_jdbc_version="latest"
    mongodb_liquibase_version="latest"
    
    find_version_from_git_tags mongodb_jdbc_version "https://github.com/mongodb/mongo-jdbc-driver"
    find_version_from_git_tags mongodb_liquibase_version "https://github.com/liquibase/liquibase-mongodb" "tags/liquibase-mongodb-"
    
    curl -sSL "https://repo1.maven.org/maven2/org/mongodb/mongodb-jdbc/${mongodb_jdbc_version}/mongodb-jdbc-${mongodb_jdbc_version}-all.jar" -o mongodb-jdbc.jar
    curl -sSL "https://github.com/liquibase/liquibase-mongodb/releases/download/liquibase-mongodb-${mongodb_liquibase_version}/liquibase-mongodb-${mongodb_liquibase_version}.jar" -o liquibase-mongodb.jar

    cp mongodb-jdbc.jar $LIQUIBASE_DIR/lib
    cp liquibase-mongodb.jar $LIQUIBASE_DIR/lib

    rm *.jar
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"