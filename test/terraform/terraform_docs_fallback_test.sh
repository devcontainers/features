#!/bin/bash

set -e

# Import test library for `check` command
source dev-container-features-test-lib

# Check to make sure the user is vscode
check "user is vscode" whoami | grep vscode

# Terraform Docs specific tests
check "terraform-docs version as installed by feature" terraform-docs --version

TERRAFORM_DOCS_SHA256="automatic"

handle_error() {
    echo "Error occurred on line ${BASH_LINENO[0]}"
    exit 1
}

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

install_tfdocs() {
    TERRAFORM_DOCS_VERSION=$1
    tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    curl -sSL -o /tmp/tf-downloads/${tfdocs_filename} https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/${tfdocs_filename}
}

try_install_terraform_docs_dummy_version() {
    mkdir -p /tmp/tf-downloads
    cd /tmp/tf-downloads
    TERRAFORM_DOCS_VERSION="1.2.xyz"
    echo -e "\nInstalling TERRAFORM_DOCS dummy version.." v${TERRAFORM_DOCS_VERSION}
    tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    echo "(*) Downloading Terraform docs... ${tfdocs_filename}"
    install_tfdocs "$TERRAFORM_DOCS_VERSION"
    if grep -q "Not Found" "/tmp/tf-downloads/${tfdocs_filename}"; then
        TERRAFORM_DOCS_VERSION=$(install_prev_vers "tfdocs" "${TERRAFORM_DOCS_VERSION}" "https://api.github.com/repos/terraform-docs/terraform-docs/releases" | grep "The installed version");
        TERRAFORM_DOCS_VERSION=$(echo "${TERRAFORM_DOCS_VERSION}" | sed 's/The installed version: //');
        tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    fi
    if [ "${TERRAFORM_DOCS_SHA256}" != "dev-mode" ]; then
        if [ "${TERRAFORM_DOCS_SHA256}" = "automatic" ]; then
            curl -sSL -o tfdocs_SHA256SUMS https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}.sha256sum
        else
            echo "${TERRAFORM_DOCS_SHA256} *${tfsec_filename}" > tfdocs_SHA256SUMS
        fi
        sha256sum --ignore-missing -c tfdocs_SHA256SUMS
    fi
    mkdir -p /tmp/tf-downloads/tfdocs
    tar -xzf /tmp/tf-downloads/${tfdocs_filename} -C /tmp/tf-downloads/tfdocs
    sudo chmod a+x /tmp/tf-downloads/tfdocs/terraform-docs
    sudo mv -f /tmp/tf-downloads/tfdocs/terraform-docs /usr/local/bin/terraform-docs

    rm -rf /tmp/tf-downloads ${GNUPGHOME}
}

try_install_terraform_docs_dummy_version


check "terraform-docs version as installed by test" terraform-docs --version

# Report result
reportResults