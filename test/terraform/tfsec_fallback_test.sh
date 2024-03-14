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
    curl -s "${REPO_URL}/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

install_prev_vers() {
    PKG_NAME=$1
    FAILED_VERSION=$2
    REPO_URL=$3
    echo -e "\n(!) Failed to fetch the latest artifacts for ${PKG_NAME} v${FAILED_VERSION}..."
    PREVIOUS_VERSION=$(get_previous_version "${REPO_URL}")
    echo -e "\nAttempting to install ${PREVIOUS_VERSION}"
    echo "The installed version: ${PREVIOUS_VERSION#v}"
    INSTALLER_FN="install_${PKG_NAME}"
    $INSTALLER_FN "${PREVIOUS_VERSION#v}"
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
        TFSEC_VERSION=$(install_prev_vers "tfsec" "${TFSEC_VERSION}" "https://api.github.com/repos/aquasecurity/tfsec/releases" | grep "The installed version");
        TFSEC_VERSION=$(echo "${TFSEC_VERSION}" | sed 's/The installed version: //');
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