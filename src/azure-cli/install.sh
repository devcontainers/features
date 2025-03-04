#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/azcli.md
# Maintainer: The VS Code and Codespaces Teams

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

AZ_VERSION=${VERSION:-"latest"}
AZ_EXTENSIONS=${EXTENSIONS}
AZ_INSTALLBICEP=${INSTALLBICEP:-false}
AZ_BICEPVERSION=${BICEPVERSION:-latest}
INSTALL_USING_PYTHON=${INSTALLUSINGPYTHON:-false}
MICROSOFT_GPG_KEYS_URI="https://packages.microsoft.com/keys/microsoft.asc"
AZCLI_ARCHIVE_ARCHITECTURES="amd64 arm64"
AZCLI_ARCHIVE_VERSION_CODENAMES="stretch bookworm buster bullseye bionic focal jammy noble"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

if [ -z "${_REMOTE_USER}" ]; then
    echo -e 'Feature script must be executed by a tool that implements the dev container specification. See https://containers.dev/ for more information.'
    exit 1
fi

echo "Effective REMOTE_USER: ${_REMOTE_USER}"

apt_get_update()
{
    echo "Running apt-get update..."
    apt-get update -y
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

# Soft version matching that resolves a version for a given package in the *current apt-cache*
# Return value is stored in first argument (the unprocessed version)
apt_cache_version_soft_match() {
    
    # Version
    local variable_name="$1"
    local requested_version=${!variable_name}
    # Package Name
    local package_name="$2"
    # Exit on no match?
    local exit_on_no_match="${3:-true}"

    # Ensure we've exported useful variables
    . /etc/os-release
    local architecture="$(dpkg --print-architecture)"
    
    dot_escaped="${requested_version//./\\.}"
    dot_plus_escaped="${dot_escaped//+/\\+}"
    # Regex needs to handle debian package version number format: https://www.systutorials.com/docs/linux/man/5-deb-version/
    version_regex="^(.+:)?${dot_plus_escaped}([\\.\\+ ~:-]|$)"
    set +e # Don't exit if finding version fails - handle gracefully
        fuzzy_version="$(apt-cache madison ${package_name} | awk -F"|" '{print $2}' | sed -e 's/^[ \t]*//' | grep -E -m 1 "${version_regex}")"
    set -e
    if [ -z "${fuzzy_version}" ]; then
        echo "(!) No full or partial for package \"${package_name}\" match found in apt-cache for \"${requested_version}\" on OS ${ID} ${VERSION_CODENAME} (${architecture})."

        if $exit_on_no_match; then
            echo "Available versions:"
            apt-cache madison ${package_name} | awk -F"|" '{print $2}' | grep -oP '^(.+:)?\K.+'
            exit 1 # Fail entire script
        else
            echo "Continuing to fallback method (if available)"
            return 1;
        fi
    fi

    # Globally assign fuzzy_version to this value
    # Use this value as the return value of this function
    declare -g ${variable_name}="=${fuzzy_version}"
    echo "${variable_name} ${!variable_name}"
}

install_using_apt() {
    # Install dependencies
    check_packages apt-transport-https curl ca-certificates gnupg2 dirmngr
    # Import key safely (new 'signed-by' method rather than deprecated apt-key approach) and install
    curl -sSL ${MICROSOFT_GPG_KEYS_URI} | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg
    echo "deb [arch=${architecture} signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/azure-cli/ ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/azure-cli.list
    apt-get update

    if [ "${AZ_VERSION}" = "latest" ] || [ "${AZ_VERSION}" = "lts" ] || [ "${AZ_VERSION}" = "stable" ]; then
        # Empty, meaning grab the "latest" in the apt repo
        AZ_VERSION=""
    else
        # Sets AZ_VERSION to our desired version, if match found.
        apt_cache_version_soft_match AZ_VERSION "azure-cli" false
        if [ "$?" != 0 ]; then
            return 1
        fi
    fi

    if ! (apt-get install -yq azure-cli${AZ_VERSION}); then
        rm -f /etc/apt/sources.list.d/azure-cli.list
        return 1
    fi
}

install_using_pip_strategy() {
    local ver=""
    if [ "${AZ_VERSION}" = "latest" ] || [ "${AZ_VERSION}" = "lts" ] || [ "${AZ_VERSION}" = "stable" ]; then
        # Empty, meaning grab the "latest" in the apt repo
        ver=""
    else
        ver="==${AZ_VERSION}"
    fi

    if [ "${INSTALL_USING_PYTHON}" = "true" ]; then
        install_with_complete_python_installation "${ver}" || install_with_pipx "${ver}" || return 1
    else
        install_with_pipx "${ver}" || install_with_complete_python_installation "${ver}" || return 1
    fi
}

install_with_pipx() {
    echo "(*) Attempting to install globally with pipx..."
    local ver="$1"
    export 
    local 

    if ! type pipx > /dev/null 2>&1; then
        echo "(*) Installing pipx..."
        check_packages pipx
        pipx ensurepath # Ensures PIPX_BIN_DIR is on the PATH
    fi

    PIPX_HOME="/usr/local/pipx" \
    PIPX_BIN_DIR=/usr/local/bin \
    pipx install azure-cli${ver}

    echo "(*) Finished installing globally with pipx."
}

install_with_complete_python_installation() {
    local ver="$1"
    echo "(*) No pre-built binaries available in apt-cache. Installing via pip3."
    if ! dpkg -s python3-minimal python3-pip libffi-dev python3-venv > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install python3-minimal python3-pip libffi-dev python3-venv
    fi
    export PIPX_HOME=/usr/local/pipx
    mkdir -p ${PIPX_HOME}
    export PIPX_BIN_DIR=/usr/local/bin
    export PYTHONUSERBASE=/tmp/pip-tmp
    export PIP_CACHE_DIR=/tmp/pip-tmp/cache
    pipx_bin=pipx
    if ! type pipx > /dev/null 2>&1; then
        pip3 install --disable-pip-version-check --no-cache-dir --user pipx
        pipx_bin=/tmp/pip-tmp/bin/pipx
    fi

    set +e
        ${pipx_bin} install --pip-args '--no-cache-dir --force-reinstall' -f azure-cli${ver}

        # Fail gracefully
        if [ "$?" != 0 ]; then
            echo "Could not install azure-cli${ver} via pip3"
            rm -rf /tmp/pip-tmp
            return 1
        fi
    set -e
}

export DEBIAN_FRONTEND=noninteractive

# See if we're on x86_64 or AARCH64 and if so, install via apt-get, otherwise use pip3
echo "(*) Installing Azure CLI..."
. /etc/os-release
architecture="$(dpkg --print-architecture)"
CACHED_AZURE_VERSION="${AZ_VERSION}" # In case we need to fallback to pip and the apt path has modified the AZ_VERSION variable.
if [ "${INSTALL_USING_PYTHON}" != "true" ]; then
    if [[ "${AZCLI_ARCHIVE_ARCHITECTURES}" = *"${architecture}"* ]] && [[  "${AZCLI_ARCHIVE_VERSION_CODENAMES}" = *"${VERSION_CODENAME}"* ]]; then
        install_using_apt || use_pip="true"
    fi
else
    use_pip="true"
fi

if [ "${use_pip}" = "true" ]; then 
    AZ_VERSION=${CACHED_AZURE_VERSION}
    install_using_pip_strategy

    if [ "$?" != 0 ]; then
        echo "Please provide a valid version for your distribution ${ID} ${VERSION_CODENAME} (${architecture})."
        echo
        echo "Valid versions in current apt-cache"
        apt-cache madison azure-cli | awk -F"|" '{print $2}' | grep -oP '^(.+:)?\K.+'
        exit 1
    fi
fi

# If Azure CLI extensions are requested, loop through and install 
if [ ${#AZ_EXTENSIONS[@]} -gt 0 ]; then
    echo "Installing Azure CLI extensions: ${AZ_EXTENSIONS}"
    extensions=(`echo ${AZ_EXTENSIONS} | tr ',' ' '`)
    for i in "${extensions[@]}"
    do
        echo "Installing ${i}"
        su ${_REMOTE_USER} -c "az extension add --name ${i} -y" || continue
    done
fi

if [ "${AZ_INSTALLBICEP}" = "true" ]; then
    # Install dependencies
    check_packages apt-transport-https curl 
    
    # Properly install Azure Bicep based on current architecture
    # The `az bicep install` command installs the linux-x64 binary even on arm64 devcontainers
    # The `az bicep install --target-platform` could be a solution; however, linux-arm64 is not an allowed value for this argument yet
    # Manually installing Bicep and moving to the appropriate directory where az expects it to be
    
    if [ "${AZ_BICEPVERSION}" = "latest" ]; then
        bicep_download_path="https://github.com/Azure/bicep/releases/latest/download"
    else
        bicep_download_path="https://github.com/Azure/bicep/releases/download/${AZ_BICEPVERSION}"
    fi

    if [ "${architecture}" = "arm64" ]; then
        curl -Lo bicep ${bicep_download_path}/bicep-linux-arm64
    else 
        curl -Lo bicep ${bicep_download_path}/bicep-linux-x64
    fi
    
    chmod +x ./bicep
    mv ./bicep /usr/local/bin/bicep

    # Add a symlink so bicep can be accessed as a standalone executable or as part of az
    mkdir -p ${_REMOTE_USER_HOME}/.azure/bin
    chown -hR ${_REMOTE_USER}:${_REMOTE_USER} ${_REMOTE_USER_HOME}/.azure
    ln -s /usr/local/bin/bicep ${_REMOTE_USER_HOME}/.azure/bin/bicep
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
