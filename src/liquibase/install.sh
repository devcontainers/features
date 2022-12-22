#!/bin/bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*


LIQUIBASE_VERSION="${VERSION:-"latest"}"

LIQUIBASE_SHA256="6113f652d06a71556d6ed4a8bb371ab2d843010cb0365379e83df8b4564a6a76"

LIQUIBASE_DIR="${LIQUIBASE_DIR:-"/usr/local/liquibase"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

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

# Fetch latest version of Hugo if needed
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

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"