#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

handle_error() {
    echo "Error occurred on line ${BASH_LINENO[0]}"
    exit 1
}

TFSEC_SHA256="automatic"

# Trap errors and call the error handling function
trap 'handle_error' ERR

architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

# TFSec specific tests
check "tfsec version as installed by feature" tfsec --version

# Function to fetch the version released prior to the latest version
get_previous_version() {
    REPO_URL=$1
    curl -s "${REPO_URL}/latest" | jq -r '.tag_name'
}

install_previous_version() {
    local given_version=$1
    local requested_version=${!given_version}
    local PKG_NAME=$2
    local REPO_URL=$3
    echo -e "\n(!) Failed to fetch the latest artifacts for ${PKG_NAME} v${requested_version}..."
    requested_version=$(get_previous_version "${REPO_URL}")
    echo -e "\nAttempting to install ${requested_version}"
    declare -g ${given_version}="${requested_version#v}"
    INSTALLER_FN="install_${PKG_NAME}"
    $INSTALLER_FN "${requested_version#v}"
    echo "${given_version}=${!given_version}"
}

install_tfsec() {
    TFSEC_VERSION=$1
    tfsec_filename="tfsec_${TFSEC_VERSION}_linux_${architecture}.tar.gz"
    curl -sSL -o /tmp/tf-downloads/${tfsec_filename} https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/${tfsec_filename}
}

try_install_tfsec_dummy_version() {
    mkdir -p /tmp/tf-downloads
    cd /tmp/tf-downloads
    TFSEC_VERSION="1.2.xyz"
    echo -e "\nInstalling TFSEC dummy version.." v${TFSEC_VERSION}
    tfsec_filename="tfsec_${TFSEC_VERSION}_linux_${architecture}.tar.gz"
    echo "(*) Downloading TFSec... ${tfsec_filename}"
    install_tfsec "$TFSEC_VERSION"
    if grep -q "Not Found" "/tmp/tf-downloads/${tfsec_filename}"; then 
        install_previous_version TFSEC_VERSION "tfsec" "https://api.github.com/repos/aquasecurity/tfsec/releases"
        tfsec_filename="tfsec_${TFSEC_VERSION}_linux_${architecture}.tar.gz"
    fi
    if [ "${TFSEC_SHA256}" != "dev-mode" ]; then
        if [ "${TFSEC_SHA256}" = "automatic" ]; then
            curl -sSL -o tfsec_SHA256SUMS https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec_${TFSEC_VERSION}_checksums.txt
        else
            echo "${TFSEC_SHA256} *${tfsec_filename}" > tfsec_SHA256SUMS
        fi
        sha256sum --ignore-missing -c tfsec_SHA256SUMS
    fi
    mkdir -p /tmp/tf-downloads/tfsec
    tar -xzf /tmp/tf-downloads/${tfsec_filename} -C /tmp/tf-downloads/tfsec
    chmod a+x /tmp/tf-downloads/tfsec/tfsec
    sudo mv -f /tmp/tf-downloads/tfsec/tfsec /usr/local/bin/tfsec
}

try_install_tfsec_dummy_version

check "tfsec version as installed by test after fallbacking from the dummy version" tfsec --version

# Report result
reportResults