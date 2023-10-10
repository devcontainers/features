#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/python.md
# Maintainer: The VS Code and Codespaces Teams

PYTHON_VERSION="${VERSION:-"latest"}" # 'system' or 'os-provided' checks the base image first, else installs 'latest'
INSTALL_PYTHON_TOOLS="${INSTALLTOOLS:-"true"}"
OPTIMIZE_BUILD_FROM_SOURCE="${OPTIMIZE:-"false"}"
PYTHON_INSTALL_PATH="${INSTALLPATH:-"/usr/local/python"}"
OVERRIDE_DEFAULT_VERSION="${OVERRIDEDEFAULTVERSION:-"true"}"

export PIPX_HOME=${PIPX_HOME:-"/usr/local/py-utils"}

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
UPDATE_RC="${UPDATE_RC:-"true"}"
USE_ORYX_IF_AVAILABLE="${USEORYXIFAVAILABLE:-"true"}"

INSTALL_JUPYTERLAB="${INSTALLJUPYTERLAB:-"false"}"
CONFIGURE_JUPYTERLAB_ALLOW_ORIGIN="${CONFIGUREJUPYTERLABALLOWORIGIN:-""}"

# Comma-separated list of python versions to be installed
# alongside PYTHON_VERSION, but not set as default.
ADDITIONAL_VERSIONS="${ADDITIONALVERSIONS:-""}"

DEFAULT_UTILS=("pylint" "flake8" "autopep8" "black" "yapf" "mypy" "pydocstyle" "pycodestyle" "bandit" "pipenv" "virtualenv" "pytest")
PYTHON_SOURCE_GPG_KEYS="64E628F8D684696D B26995E310250568 2D347EA6AA65421D FB9921286F5E1540 3A5CA953F73C700D 04C367C218ADD4FF 0EDDC5F26A45C816 6AF053F07D9DC8D2 C9BE28DEE6DF025C 126EB563A74B06BF D9866941EA5BBD71 ED9D77D5"
GPG_KEY_SERVERS="keyserver hkp://keyserver.ubuntu.com
keyserver hkp://keyserver.ubuntu.com:80
keyserver hkps://keys.openpgp.org
keyserver hkp://keyserver.pgp.com"

KEYSERVER_PROXY="${HTTPPROXY:-"${HTTP_PROXY:-""}"}"

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

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    if [ ! -z "$2" ]; then
        mkdir -p "$(dirname \"$2\")"
        keyring_args="--no-default-keyring --keyring $2"
    fi
    if [ ! -z "${KEYSERVER_PROXY}" ]; then
        keyring_args="${keyring_args} --keyserver-options http-proxy=${KEYSERVER_PROXY}"
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

# Use Oryx to install something using a partial version match
oryx_install() {
    local platform=$1
    local requested_version=$2
    local target_folder=${3:-none}
    local ldconfig_folder=${4:-none}
    echo "(*) Installing ${platform} ${requested_version} using Oryx..."
    check_packages jq
    # Soft match if full version not specified
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local version_list="$(oryx platforms --json | jq -r ".[] | select(.Name == \"${platform}\") | .Versions | sort | reverse | @tsv" | tr '\t' '\n' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$')"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            requested_version="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            requested_version="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
        if [ -z "${requested_version}" ] || ! echo "${version_list}" | grep "^${requested_version//./\\.}$" > /dev/null 2>&1; then
            echo -e "(!) Oryx does not support ${platform} version $2\nValid values:\n${version_list}" >&2
            return 1
        fi
        echo "(*) Using ${requested_version} in place of $2."
    fi

    export ORYX_ENV_TYPE=vsonline-present ORYX_PREFER_USER_INSTALLED_SDKS=true ENABLE_DYNAMIC_INSTALL=true DYNAMIC_INSTALL_ROOT_DIR=/opt
    oryx prep --skip-detection --platforms-and-versions "${platform}=${requested_version}"
    local opt_folder="/opt/${platform}/${requested_version}"
    if [ "${target_folder}" != "none" ] && [ "${target_folder}" != "${opt_folder}" ]; then
        ln -s "${opt_folder}" "${target_folder}"
    fi
    # Update library path add to conf
    if [ "${ldconfig_folder}" != "none" ]; then
        echo "/opt/${platform}/${requested_version}/lib" >> "/etc/ld.so.conf.d/${platform}.conf"
        ldconfig
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

add_symlink() {
    if [[ ! -d "${CURRENT_PATH}" ]]; then
        ln -s -r "${INSTALL_PATH}" "${CURRENT_PATH}" 
    fi

    if [ "${OVERRIDE_DEFAULT_VERSION}" = "true" ]; then
        if [[ $(ls -l ${CURRENT_PATH}) != *"-> ${INSTALL_PATH}"* ]] ; then
            rm "${CURRENT_PATH}"
            ln -s -r "${INSTALL_PATH}" "${CURRENT_PATH}" 
        fi
    fi
}

install_from_source() {
    VERSION=$1 
    echo "(*) Building Python ${VERSION} from source..."
    # Install prereqs if missing
    check_packages curl ca-certificates gnupg2 tar make gcc libssl-dev zlib1g-dev libncurses5-dev \
                libbz2-dev libreadline-dev libxml2-dev xz-utils libgdbm-dev tk-dev dirmngr \
                libxmlsec1-dev libsqlite3-dev libffi-dev liblzma-dev uuid-dev 
    if ! type git > /dev/null 2>&1; then
        check_packages git
    fi

    # Find version using soft match
    find_version_from_git_tags VERSION "https://github.com/python/cpython"

    INSTALL_PATH="${PYTHON_INSTALL_PATH}/${VERSION}"
    
    if [ -d "${INSTALL_PATH}" ]; then
        echo "(!) Python version ${VERSION} already exists."
        exit 1
    fi

    # Download tgz of source
    mkdir -p /tmp/python-src ${INSTALL_PATH}
    cd /tmp/python-src
    local tgz_filename="Python-${VERSION}.tgz"
    local tgz_url="https://www.python.org/ftp/python/${VERSION}/${tgz_filename}"
    echo "Downloading ${tgz_filename}..."
    curl -sSL -o "/tmp/python-src/${tgz_filename}" "${tgz_url}"

    # Verify signature
    receive_gpg_keys PYTHON_SOURCE_GPG_KEYS
    echo "Downloading ${tgz_filename}.asc..."
    curl -sSL -o "/tmp/python-src/${tgz_filename}.asc" "${tgz_url}.asc"
    gpg --verify "${tgz_filename}.asc"

    # Update min protocol for testing only - https://bugs.python.org/issue41561
    cp /etc/ssl/openssl.cnf /tmp/python-src/
    sed -i -E 's/MinProtocol[=\ ]+.*/MinProtocol = TLSv1.0/g' /tmp/python-src/openssl.cnf
    export OPENSSL_CONF=/tmp/python-src/openssl.cnf

    # Untar and build
    tar -xzf "/tmp/python-src/${tgz_filename}" -C "/tmp/python-src" --strip-components=1
    local config_args=""
    if [ "${OPTIMIZE_BUILD_FROM_SOURCE}" = "true" ]; then
        config_args="--enable-optimizations"
    fi
    ./configure --prefix="${INSTALL_PATH}" --with-ensurepip=install ${config_args}
    make -j 8
    make install
    cd /tmp
    rm -rf /tmp/python-src ${GNUPGHOME} /tmp/vscdc-settings.env

    ln -s "${INSTALL_PATH}/bin/python3" "${INSTALL_PATH}/bin/python"
    ln -s "${INSTALL_PATH}/bin/pip3" "${INSTALL_PATH}/bin/pip"
    ln -s "${INSTALL_PATH}/bin/idle3" "${INSTALL_PATH}/bin/idle"
    ln -s "${INSTALL_PATH}/bin/pydoc3" "${INSTALL_PATH}/bin/pydoc"
    ln -s "${INSTALL_PATH}/bin/python3-config" "${INSTALL_PATH}/bin/python-config"

    add_symlink

}

install_using_oryx() {
    VERSION=$1 
    INSTALL_PATH="${PYTHON_INSTALL_PATH}/${VERSION}"
    
    if [ -d "${INSTALL_PATH}" ]; then
        echo "(!) Python version ${VERSION} already exists."
        exit 1
    fi

    # The python install root path may not exist, so create it
    mkdir -p "${PYTHON_INSTALL_PATH}"
    oryx_install "python" "${VERSION}" "${INSTALL_PATH}" "lib" || return 1

    ln -s "${INSTALL_PATH}/bin/idle3" "${INSTALL_PATH}/bin/idle"
    ln -s "${INSTALL_PATH}/bin/pydoc3" "${INSTALL_PATH}/bin/pydoc"
    ln -s "${INSTALL_PATH}/bin/python3-config" "${INSTALL_PATH}/bin/python-config"

    add_symlink
}

sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        $COMMAND
    fi
}

install_user_package() {
    INSTALL_UNDER_ROOT="$1"
    PACKAGE="$2"

    if [ "$INSTALL_UNDER_ROOT" = true ]; then
        sudo_if "${PYTHON_SRC}" -m pip install --upgrade --no-cache-dir "$PACKAGE"
    else
        sudo_if "${PYTHON_SRC}" -m pip install --user --upgrade --no-cache-dir "$PACKAGE"
    fi
}

add_user_jupyter_config() {
    CONFIG_DIR="$1"
    CONFIG_FILE="$2"

    # Make sure the config file exists or create it with proper permissions
    test -d "$CONFIG_DIR" || sudo_if mkdir "$CONFIG_DIR"
    test -f "$CONFIG_FILE" || sudo_if touch "$CONFIG_FILE"

    # Don't write the same config more than once
    grep -q "$3" "$CONFIG_FILE" || echo "$3" >> "$CONFIG_FILE"
}

install_python() {
    version=$1
    # If the os-provided versions are "good enough", detect that and bail out.
    if [ ${version} = "os-provided" ] || [ ${version} = "system" ]; then
        check_packages python3 python3-doc python3-pip python3-venv python3-dev python3-tk
        INSTALL_PATH="/usr"

        local current_bin_path="${CURRENT_PATH}/bin"
        if [ "${OVERRIDE_DEFAULT_VERSION}" = "true" ]; then
            rm -rf "${current_bin_path}"
        fi
        if [ ! -d "${current_bin_path}" ] ; then
            mkdir -p "${current_bin_path}"
            # Add an interpreter symlink but point it to "/usr" since python is at /usr/bin/python, add other alises
            ln -s "${INSTALL_PATH}/bin/python3" "${current_bin_path}/python3"
            ln -s "${INSTALL_PATH}/bin/python3" "${current_bin_path}/python"
            ln -s "${INSTALL_PATH}/bin/pydoc3" "${current_bin_path}/pydoc3"
            ln -s "${INSTALL_PATH}/bin/pydoc3" "${current_bin_path}/pydoc"
            ln -s "${INSTALL_PATH}/bin/python3-config" "${current_bin_path}/python3-config"
            ln -s "${INSTALL_PATH}/bin/python3-config" "${current_bin_path}/python-config"
        fi

        should_install_from_source=false
    elif [ "$(dpkg --print-architecture)" = "amd64" ] && [ "${USE_ORYX_IF_AVAILABLE}" = "true" ] && type oryx > /dev/null 2>&1; then
        install_using_oryx $version || should_install_from_source=true
    else
        should_install_from_source=true
    fi
    if [ "${should_install_from_source}" = "true" ]; then
        install_from_source $version
    fi
}

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# General requirements
check_packages curl ca-certificates gnupg2 tar make gcc libssl-dev zlib1g-dev libncurses5-dev \
            libbz2-dev libreadline-dev libxml2-dev xz-utils libgdbm-dev tk-dev dirmngr \
            libxmlsec1-dev libsqlite3-dev libffi-dev liblzma-dev uuid-dev 


# Install Python from source if needed
if [ "${PYTHON_VERSION}" != "none" ]; then
    if ! cat /etc/group | grep -e "^python:" > /dev/null 2>&1; then
        groupadd -r python
    fi
    usermod -a -G python "${USERNAME}"

    CURRENT_PATH="${PYTHON_INSTALL_PATH}/current"
    
    install_python ${PYTHON_VERSION}

    # Additional python versions to be installed but not be set as default.
    if [ ! -z "${ADDITIONAL_VERSIONS}" ]; then
        OLD_INSTALL_PATH="${INSTALL_PATH}"
        OLDIFS=$IFS
        IFS=","
            read -a additional_versions <<< "$ADDITIONAL_VERSIONS"
            for version in "${additional_versions[@]}"; do
                OVERRIDE_DEFAULT_VERSION="false"
                install_python $version
            done
        INSTALL_PATH="${OLD_INSTALL_PATH}"
        IFS=$OLDIFS
    fi

    if [ ${PYTHON_VERSION} != "os-provided" ] && [ ${PYTHON_VERSION} != "system" ]; then
        updaterc "if [[ \"\${PATH}\" != *\"${CURRENT_PATH}/bin\"* ]]; then export PATH=${CURRENT_PATH}/bin:\${PATH}; fi"
        PATH="${INSTALL_PATH}/bin:${PATH}"
    fi
    
    # Updates the symlinks for os-provided, or the installed python version in other cases
    chown -R "${USERNAME}:python" "${PYTHON_INSTALL_PATH}"
    chmod -R g+r+w "${PYTHON_INSTALL_PATH}"
    find "${PYTHON_INSTALL_PATH}" -type d -print0 | xargs -0 -n 1 chmod g+s

    PYTHON_SRC="${INSTALL_PATH}/bin/python3"
else
    PYTHON_SRC=$(which python)
fi

# Install Python tools if needed
if [[ "${INSTALL_PYTHON_TOOLS}" = "true" ]] && [[ $(python --version) != "" ]]; then
    echo 'Installing Python tools...'
    export PIPX_BIN_DIR="${PIPX_HOME}/bin"
    PATH="${PATH}:${PIPX_BIN_DIR}"

    # Create pipx group, dir, and set sticky bit
    if ! cat /etc/group | grep -e "^pipx:" > /dev/null 2>&1; then
        groupadd -r pipx
    fi
    usermod -a -G pipx ${USERNAME}
    umask 0002
    mkdir -p ${PIPX_BIN_DIR}
    chown -R "${USERNAME}:pipx" ${PIPX_HOME}
    chmod -R g+r+w "${PIPX_HOME}" 
    find "${PIPX_HOME}" -type d -print0 | xargs -0 -n 1 chmod g+s

    # Update pip if not using os provided python
    if [[ $(python --version) != "" ]] || [[ ${PYTHON_VERSION} != "os-provided" ]] && [[ ${PYTHON_VERSION} != "system" ]] && [[ ${PYTHON_VERSION} != "none" ]]; then
        echo "Updating pip..."
        python -m pip install --no-cache-dir --upgrade pip
    fi

    # Install tools
    echo "Installing Python tools..."
    export PYTHONUSERBASE=/tmp/pip-tmp
    export PIP_CACHE_DIR=/tmp/pip-tmp/cache
    PIPX_DIR=""
    if ! type pipx > /dev/null 2>&1; then
        pip3 install --disable-pip-version-check --no-cache-dir --user pipx 2>&1
        /tmp/pip-tmp/bin/pipx install --pip-args=--no-cache-dir pipx
        PIPX_DIR="/tmp/pip-tmp/bin/"
    fi
    for util in "${DEFAULT_UTILS[@]}"; do
        if ! type ${util} > /dev/null 2>&1; then
            "${PIPX_DIR}pipx" install --system-site-packages --pip-args '--no-cache-dir --force-reinstall' ${util}
        else
            echo "${util} already installed. Skipping."
        fi
    done
    rm -rf /tmp/pip-tmp

    updaterc "export PIPX_HOME=\"${PIPX_HOME}\""
    updaterc "export PIPX_BIN_DIR=\"${PIPX_BIN_DIR}\""
    updaterc "if [[ \"\${PATH}\" != *\"\${PIPX_BIN_DIR}\"* ]]; then export PATH=\"\${PATH}:\${PIPX_BIN_DIR}\"; fi"
fi

# Install JupyterLab if needed
if [ "${INSTALL_JUPYTERLAB}" = "true" ]; then
    if [ -z "${PYTHON_SRC}" ]; then
        echo "(!) Could not install Jupyterlab. Python not found."
        exit 1
    fi

    INSTALL_UNDER_ROOT=true
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        INSTALL_UNDER_ROOT=false
    fi

    install_user_package $INSTALL_UNDER_ROOT jupyterlab
    install_user_package $INSTALL_UNDER_ROOT jupyterlab-git

    # Configure JupyterLab if needed
    if [ -n "${CONFIGURE_JUPYTERLAB_ALLOW_ORIGIN}" ]; then
        # Resolve config directory
        CONFIG_DIR="/root/.jupyter"
        if [ "$INSTALL_UNDER_ROOT" = false ]; then
            CONFIG_DIR="/home/$USERNAME/.jupyter"
        fi

        CONFIG_FILE="$CONFIG_DIR/jupyter_server_config.py"

        add_user_jupyter_config $CONFIG_DIR $CONFIG_FILE "c.ServerApp.allow_origin = '${CONFIGURE_JUPYTERLAB_ALLOW_ORIGIN}'"
        add_user_jupyter_config $CONFIG_DIR $CONFIG_FILE "c.NotebookApp.allow_origin = '${CONFIGURE_JUPYTERLAB_ALLOW_ORIGIN}'"
    fi
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
