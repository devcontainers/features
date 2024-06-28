#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/ruby.md
# Maintainer: The VS Code and Codespaces Teams

RUBY_VERSION="${VERSION:-"latest"}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"
INSTALL_RUBY_TOOLS="${INSTALL_RUBY_TOOLS:-"true"}"

# Comma-separated list of ruby versions to be installed (with rvm)
# alongside RUBY_VERSION, but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

# Note: ruby-debug-ide will install the right version of debase if missing and
# installing debase directly fails on Ruby 3.1.0 as of 1/7/2022, so omitting.
# installing ruby-debug-ide on debian fails, so omitting.
DEFAULT_GEMS="rake"

RVM_GPG_KEYS="409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB"

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

# Get the list of GPG key servers that are reachable
get_gpg_key_servers() {
    declare -A keyservers_curl_map=(
        ["hkp://keyserver.ubuntu.com"]="http://keyserver.ubuntu.com:11371"
        ["hkp://keyserver.ubuntu.com:80"]="http://keyserver.ubuntu.com"
        ["hkps://keys.openpgp.org"]="https://keys.openpgp.org"
        ["hkp://keyserver.pgp.com"]="http://keyserver.pgp.com:11371"
    )

    local curl_args=""
    local keyserver_reachable=false  # Flag to indicate if any keyserver is reachable

    if [ ! -z "${KEYSERVER_PROXY}" ]; then
        curl_args="--proxy ${KEYSERVER_PROXY}"
    fi

    for keyserver in "${!keyservers_curl_map[@]}"; do
        local keyserver_curl_url="${keyservers_curl_map[${keyserver}]}"
        if curl -s ${curl_args} --max-time 5 ${keyserver_curl_url} > /dev/null; then
            echo "keyserver ${keyserver}"
            keyserver_reachable=true
        else
            echo "(*) Keyserver ${keyserver} is not reachable." >&2
        fi
    done

    if ! $keyserver_reachable; then
        echo "(!) No keyserver is reachable." >&2
        exit 1
    fi
}

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    if [ ! -z "$2" ]; then
        keyring_args="--no-default-keyring --keyring \"$2\""
    fi

    # Install curl
    if ! type curl > /dev/null 2>&1; then
        check_packages curl
    fi

    # Use a temporary location for gpg keys to avoid polluting image
    export GNUPGHOME="/tmp/tmp-gnupg"
    mkdir -p ${GNUPGHOME}
    chmod 700 ${GNUPGHOME}
    echo -e "disable-ipv6\n$(get_gpg_key_servers)" > ${GNUPGHOME}/dirmngr.conf
    # GPG key download sometimes fails for some reason and retrying fixes it.
    local retry_count=0
    local gpg_ok="false"
    set +e
    until [ "${gpg_ok}" = "true" ] || [ "${retry_count}" -eq "5" ]; 
    do
        echo "(*) Downloading GPG key..."
        ( echo "${keys}" | xargs -n 1 gpg -q ${keyring_args} --recv-keys) 2>&1 && gpg_ok="true"
        if [ "${gpg_ok}" != "true" ]; then
            echo "(*) Failed getting key, retrying in 10s..."
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
    local version_suffix_regex=$6
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

architecture="$(uname -m)"
if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
    echo "(!) Architecture $architecture unsupported"
    exit 1
fi

# Install dependencies
check_packages curl ca-certificates software-properties-common build-essential gnupg2 libreadline-dev \
    procps dirmngr gawk autoconf automake bison libffi-dev libgdbm-dev libncurses5-dev \
    libsqlite3-dev libtool libyaml-dev pkg-config sqlite3 zlib1g-dev libgmp-dev libssl-dev
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Function to fetch the version released prior to the latest version
get_previous_version() {
    local url=$1
    local repo_url=$2
    variable_name=$3
    prev_version=${!variable_name}
    
    output=$(curl -s "$repo_url");

    #install jq
    check_packages jq

    message=$(echo "$output" | jq -r '.message')

    if [[ $message == "API rate limit exceeded"* ]]; then
        echo -e "\nAn attempt to find latest version using GitHub Api Failed... \nReason: ${message}"
        echo -e "\nAttempting to find latest version using GitHub tags."
        find_prev_version_from_git_tags prev_version "$url" "tags/v" "_"
        declare -g ${variable_name}="${prev_version}"
    else 
        echo -e "\nAttempting to find latest version using GitHub Api."
        version=$(echo "$output" | jq -r '.tag_name' | tr '_' '.')
        declare -g ${variable_name}="${version#v}"
    fi  
    echo "${variable_name}=${!variable_name}"
}

get_github_api_repo_url() {
    local url=$1
    echo "${url/https:\/\/github.com/https:\/\/api.github.com\/repos}/releases/latest"
}


# Figure out correct version of a three part version number is not passed
RUBY_URL="https://github.com/ruby/ruby"
ORIGINAL_RUBY_VERSION=$RUBY_VERSION
find_version_from_git_tags RUBY_VERSION $RUBY_URL "tags/v" "_"

set_rvm_install_args() {
    RUBY_VERSION=$1
    if [ "${RUBY_VERSION}" = "none" ]; then
        RVM_INSTALL_ARGS=""
    elif [[ "$(ruby -v)" = *"${RUBY_VERSION}"* ]]; then
        echo "(!) Ruby is already installed with version ${RUBY_VERSION}. Skipping..."
        RVM_INSTALL_ARGS=""
    else
        if [ "${RUBY_VERSION}" = "latest" ] || [ "${RUBY_VERSION}" = "current" ] || [ "${RUBY_VERSION}" = "lts" ]; then
            RVM_INSTALL_ARGS="--ruby"
            RUBY_VERSION=""
        else
            RVM_INSTALL_ARGS="--ruby=${RUBY_VERSION}"
        fi
        if [ "${INSTALL_RUBY_TOOLS}" = "true" ]; then
            SKIP_GEM_INSTALL="true"
        else 
            DEFAULT_GEMS=""
        fi
    fi
}

install_previous_version() {
    if [[ $ORIGINAL_RUBY_VERSION == "latest" ]]; then
        repo_url=$(get_github_api_repo_url "$RUBY_URL")
        get_previous_version "${RUBY_URL}" "${repo_url}" RUBY_VERSION
        set_rvm_install_args $RUBY_VERSION
        curl -sSL https://get.rvm.io | bash -s stable --ignore-dotfiles ${RVM_INSTALL_ARGS} --with-default-gems="${DEFAULT_GEMS}" 2>&1
    else 
        echo "Failed to install Ruby version $ORIGINAL_RUBY_VERSION. Exiting..."
    fi
}

# Just install Ruby if RVM already installed
if rvm --version > /dev/null; then
    echo "Ruby Version Manager already exists."
    if [[ "$(ruby -v)" = *"${RUBY_VERSION}"* ]]; then
        echo "(!) Ruby is already installed with version ${RUBY_VERSION}. Skipping..."
    elif [ "${RUBY_VERSION}" != "none" ]; then
        echo "Installing specified Ruby version."
        su ${USERNAME} -c "rvm install ruby ${RUBY_VERSION}"
    fi
    SKIP_GEM_INSTALL="false"
    SKIP_RBENV_RBUILD="true"
else
    # Install RVM
    receive_gpg_keys RVM_GPG_KEYS
    # Determine appropriate settings for rvm installer
    set_rvm_install_args $RUBY_VERSION
    # Create rvm group as a system group to reduce the odds of conflict with local user UIDs
    if ! cat /etc/group | grep -e "^rvm:" > /dev/null 2>&1; then
        groupadd -r rvm
    fi
    # Install rvm
    curl -sSL https://get.rvm.io | bash -s stable --ignore-dotfiles ${RVM_INSTALL_ARGS} --with-default-gems="${DEFAULT_GEMS}" 2>&1 || install_previous_version
    usermod -aG rvm ${USERNAME}
    source /usr/local/rvm/scripts/rvm
    rvm fix-permissions system
    rm -rf ${GNUPGHOME}
fi

if [ "${INSTALL_RUBY_TOOLS}" = "true" ]; then   
    # Non-root user may not have "gem" in path when script is run and no ruby version
    # is installed by rvm, so handle this by using root's default gem in this case
    ROOT_GEM="$(which gem || echo "")"
    ${ROOT_GEM} install ${DEFAULT_GEMS}
fi

# VS Code server usually first in the path, so silence annoying rvm warning (that does not apply) and then source it
updaterc "if ! grep rvm_silence_path_mismatch_check_flag \$HOME/.rvmrc > /dev/null 2>&1; then echo 'rvm_silence_path_mismatch_check_flag=1' >> \$HOME/.rvmrc; fi\nsource /usr/local/rvm/scripts/rvm > /dev/null 2>&1"

# Additional ruby versions to be installed but not be set as default.
if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
    OLDIFS=$IFS
    IFS=","
        read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
        for version in "${additional_versions[@]}"; do
            # Figure out correct version of a three part version number is not passed
            find_version_from_git_tags version $RUBY_URL "tags/v" "_"
            source /usr/local/rvm/scripts/rvm
            rvm install ruby ${version}
        done
    IFS=$OLDIFS
fi

# Install rbenv/ruby-build for good measure
if [ "${SKIP_RBENV_RBUILD}" != "true" ]; then

    if [[ ! -d "/usr/local/share/rbenv" ]]; then
        git clone --depth=1 \
            -c core.eol=lf \
            -c core.autocrlf=false \
            -c fsck.zeroPaddedFilemode=ignore \
            -c fetch.fsck.zeroPaddedFilemode=ignore \
            -c receive.fsck.zeroPaddedFilemode=ignore \
            https://github.com/rbenv/rbenv.git /usr/local/share/rbenv
    fi

    if [[ ! -d "/usr/local/share/ruby-build" ]]; then
        git clone --depth=1 \
            -c core.eol=lf \
            -c core.autocrlf=false \
            -c fsck.zeroPaddedFilemode=ignore \
            -c fetch.fsck.zeroPaddedFilemode=ignore \
            -c receive.fsck.zeroPaddedFilemode=ignore \
            https://github.com/rbenv/ruby-build.git /usr/local/share/ruby-build
        mkdir -p /root/.rbenv/plugins

        ln -s /usr/local/share/ruby-build /root/.rbenv/plugins/ruby-build
    fi

    if [ "${USERNAME}" != "root" ]; then
        mkdir -p /home/${USERNAME}/.rbenv/plugins

        if [[ ! -d "/home/${USERNAME}/.rbenv/plugins/ruby-build" ]]; then
            ln -s /usr/local/share/ruby-build /home/${USERNAME}/.rbenv/plugins/ruby-build
        fi

        # Oryx expects ruby to be installed in this specific path, else it breaks the oryx magic for ruby projects.
        if [ ! -f /usr/local/rvm/gems/default/bin/ruby ]; then
            ln -s /usr/local/rvm/rubies/default/bin/ruby /usr/local/rvm/gems/default/bin
        fi

        chown -R "${USERNAME}:rvm" "/home/${USERNAME}/.rbenv/"
        chmod -R g+r+w "/home/${USERNAME}/.rbenv"
        find "/home/${USERNAME}/.rbenv" -type d | xargs -n 1 chmod g+s
    fi
fi

chown -R "${USERNAME}:rvm" "/usr/local/rvm/"
chmod -R g+r+w "/usr/local/rvm/"
find "/usr/local/rvm/" -type d | xargs -n 1 chmod g+s

# Clean up
rvm cleanup all
${ROOT_GEM} cleanup

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
