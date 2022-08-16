#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------


USERNAME=${USERNAME:-"automatic"}
UPDATE_RC=${UPDATE_RC:-"true"}

MICROSOFT_GPG_KEYS_URI="https://packages.microsoft.com/keys/microsoft.asc"

set -eu

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

function updaterc() {
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

# Function to run apt-get if needed
apt_get_update_if_needed()
{
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update_if_needed
        apt-get -y install --no-install-recommends "$@"
    fi
}

install_dotnet_using_apt() {
    echo "Attempting to auto-install dotnet..."
    install_from_microsoft_feed=false
    apt_get_update_if_needed
    apt-get -yq install dotnet6 || install_from_microsoft_feed="true"

    if [ "${install_from_microsoft_feed}" = "true" ]; then
        echo "Attempting install from microsoft apt feed..."
        curl -sSL ${MICROSOFT_GPG_KEYS_URI} | gpg --dearmor > /usr/share/keyrings/microsoft-archive-keyring.gpg
        echo "deb [arch=${architecture} signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/microsoft-${ID}-${VERSION_CODENAME}-prod ${VERSION_CODENAME} main" > /etc/apt/sources.list.d/microsoft.list
        apt-get update -y
        DOTNET_SKIP_FIRST_TIME_EXPERIENCE="true" apt-get install -yq dotnet-sdk-6.0
    fi

    echo -e "Finished attempt to install dotnet.  Sdks installed:\n"
    dotnet --list-sdks
}

# If we don't already have Oryx installed, install it now.
if  oryx --version > /dev/null ; then
    echo "oryx is already installed. Skipping installation."
    exit 0
fi

echo "Installing Oryx..."

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

. /etc/os-release
architecture="$(dpkg --print-architecture)"

# Install dependencies
check_packages git sudo curl ca-certificates apt-transport-https gnupg2 dirmngr libc-bin

if ! cat /etc/group | grep -e "^oryx:" > /dev/null 2>&1; then
    groupadd -r oryx
fi
usermod -a -G oryx "${USERNAME}"

# Install dotnet unless available
if ! dotnet --version > /dev/null ; then
    echo "'dotnet' was not detected. Attempting to install the latest version of the dotnet sdk to build oryx."
    install_dotnet_using_apt

    if ! dotnet --version > /dev/null ; then
        echo "(!) Please install Dotnet before installing Oryx"
        exit 1
    fi
fi

BUILD_SCRIPT_GENERATOR=/usr/local/buildscriptgen 
ORYX=/usr/local/oryx
GIT_ORYX=/opt/tmp

mkdir -p ${BUILD_SCRIPT_GENERATOR}
mkdir -p ${ORYX}

git clone --depth=1 https://github.com/microsoft/Oryx $GIT_ORYX

$GIT_ORYX/build/buildSln.sh

dotnet publish -property:ValidateExecutableReferencesMatchSelfContained=false -r linux-x64 -o ${BUILD_SCRIPT_GENERATOR} -c Release $GIT_ORYX/src/BuildScriptGeneratorCli/BuildScriptGeneratorCli.csproj
dotnet publish -r linux-x64 -o ${BUILD_SCRIPT_GENERATOR} -c Release $GIT_ORYX/src/BuildServer/BuildServer.csproj

chmod a+x ${BUILD_SCRIPT_GENERATOR}/GenerateBuildScript

ln -s ${BUILD_SCRIPT_GENERATOR}/GenerateBuildScript ${ORYX}/oryx
cp -f $GIT_ORYX/images/build/benv.sh ${ORYX}/benv

ORYX_INSTALL_DIR="/opt"
mkdir -p "${ORYX_INSTALL_DIR}"

updaterc "export ORYX_SDK_STORAGE_BASE_URL=https://oryx-cdn.microsoft.io && export ENABLE_DYNAMIC_INSTALL=true && DYNAMIC_INSTALL_ROOT_DIR=$ORYX_INSTALL_DIR && ORYX_PREFER_USER_INSTALLED_SDKS=true && export DEBIAN_FLAVOR=focal-scm"

chown -R "${USERNAME}:oryx" "${ORYX_INSTALL_DIR}" "${BUILD_SCRIPT_GENERATOR}" "${ORYX}"
chmod -R g+r+w "${ORYX_INSTALL_DIR}" "${BUILD_SCRIPT_GENERATOR}" "${ORYX}"
find "${ORYX_INSTALL_DIR}" -type d | xargs -n 1 chmod g+s
find "${BUILD_SCRIPT_GENERATOR}" -type d | xargs -n 1 chmod g+s
find "${ORYX}" -type d | xargs -n 1 chmod g+s

echo "Done!"
