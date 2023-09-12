#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/terraform.md
# Maintainer: The VS Code and Codespaces Teams

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

TERRAFORM_VERSION="${VERSION:-"latest"}"
TFLINT_VERSION="${TFLINT:-"latest"}"
TERRAGRUNT_VERSION="${TERRAGRUNT:-"latest"}"
INSTALL_SENTINEL=${INSTALLSENTINEL:-false}
INSTALL_TFSEC=${INSTALLTFSEC:-false}
INSTALL_TERRAFORM_DOCS=${INSTALLTERRAFORMDOCS:-false}

TERRAFORM_SHA256="${TERRAFORM_SHA256:-"automatic"}"
TFLINT_SHA256="${TFLINT_SHA256:-"automatic"}"
TERRAGRUNT_SHA256="${TERRAGRUNT_SHA256:-"automatic"}"
SENTINEL_SHA256="${SENTINEL_SHA256:-"automatic"}"
TFSEC_SHA256="${TFSEC_SHA256:-"automatic"}"
TERRAFORM_DOCS_SHA256="${TERRAFORM_DOCS_SHA256:-"automatic"}"

TERRAFORM_GPG_KEY="72D7468F"
TFLINT_GPG_KEY_URI="https://raw.githubusercontent.com/terraform-linters/tflint/v0.46.1/8CE69160EB3F2FE9.key"
GPG_KEY_SERVERS="keyserver hkps://keyserver.ubuntu.com
keyserver hkps://keys.openpgp.org
keyserver hkps://keyserver.pgp.com"
KEYSERVER_PROXY="${HTTPPROXY:-"${HTTP_PROXY:-""}"}"

architecture="$(uname -m)"
case ${architecture} in
    x86_64) architecture="amd64";;
    aarch64 | armv8*) architecture="arm64";;
    aarch32 | armv7* | armvhf*) architecture="arm";;
    i?86) architecture="386";;
    *) echo "(!) Architecture ${architecture} unsupported"; exit 1 ;;
esac

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Import the specified key in a variable name passed in as 
receive_gpg_keys() {
    local keys=${!1}
    local keyring_args=""
    if [ ! -z "$2" ]; then
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

find_sentinel_version_from_url() {
    local variable_name=$1
    local requested_version=${!variable_name}
    if [ "${requested_version}" = "none" ]; then return; fi
    local repository=$2
    if [ "$(echo "${requested_version}" | grep -o "." | wc -l)" != "2" ]; then
        local prefix='sentinel_'
        local regex="${prefix}\d.\d{2}.\d(?:-\w*)?"
        local version_list="$(wget -q $2 -O - | grep -oP ${regex} | tr -d ${prefix} | sort -rV)"
        if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ] || [ "${requested_version}" = "lts" ]; then
            declare -g ${variable_name}="$(echo "${version_list}" | head -n 1)"
        else
            set +e
            declare -g ${variable_name}="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
            set -e
        fi
    fi
    if [ -z "${!variable_name}" ] || ! echo "${version_list}" | grep "^${!variable_name//./\\.}$" >/dev/null 2>&1; then
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

# Install 'cosign' for validating signatures
# https://docs.sigstore.dev/cosign/overview/
ensure_cosign() {
    check_packages curl ca-certificates gnupg2

    if ! type cosign > /dev/null 2>&1; then
        echo "Installing cosign..."
        LATEST_COSIGN_VERSION="latest"
        find_version_from_git_tags LATEST_COSIGN_VERSION 'https://github.com/sigstore/cosign'
        curl -L "https://github.com/sigstore/cosign/releases/latest/download/cosign_${LATEST_COSIGN_VERSION}_${architecture}.deb" -o /tmp/cosign_${LATEST_COSIGN_VERSION}_${architecture}.deb
        
        dpkg -i /tmp/cosign_${LATEST_COSIGN_VERSION}_${architecture}.deb
        rm /tmp/cosign_${LATEST_COSIGN_VERSION}_${architecture}.deb
    fi
    if ! type cosign > /dev/null 2>&1; then
        echo "(!) Failed to install cosign."
        exit 1
    fi
    cosign version
}

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install dependencies if missing
check_packages curl ca-certificates gnupg2 dirmngr coreutils unzip
if ! type git > /dev/null 2>&1; then
    check_packages git
fi

# Verify requested version is available, convert latest
find_version_from_git_tags TERRAFORM_VERSION 'https://github.com/hashicorp/terraform'
find_version_from_git_tags TFLINT_VERSION 'https://github.com/terraform-linters/tflint'
find_version_from_git_tags TERRAGRUNT_VERSION 'https://github.com/gruntwork-io/terragrunt'

mkdir -p /tmp/tf-downloads
cd /tmp/tf-downloads

# Install Terraform, tflint, Terragrunt
echo "Downloading terraform..."
terraform_filename="terraform_${TERRAFORM_VERSION}_linux_${architecture}.zip"
curl -sSL -o ${terraform_filename} "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${terraform_filename}"
if [ "${TERRAFORM_SHA256}" != "dev-mode" ]; then
    if [ "${TERRAFORM_SHA256}" = "automatic" ]; then
        receive_gpg_keys TERRAFORM_GPG_KEY
        curl -sSL -o terraform_SHA256SUMS https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS 
        curl -sSL -o terraform_SHA256SUMS.sig https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS.${TERRAFORM_GPG_KEY}.sig
        gpg --verify terraform_SHA256SUMS.sig terraform_SHA256SUMS
    else
        echo "${TERRAFORM_SHA256} *${terraform_filename}" > terraform_SHA256SUMS
    fi
    sha256sum --ignore-missing -c terraform_SHA256SUMS
fi
unzip ${terraform_filename}
mv -f terraform /usr/local/bin/

if [ "${TFLINT_VERSION}" != "none" ]; then
    echo "Downloading tflint..."
    TFLINT_FILENAME="tflint_linux_${architecture}.zip"
    curl -sSL -o /tmp/tf-downloads/${TFLINT_FILENAME} https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/${TFLINT_FILENAME}
    if [ "${TFLINT_SHA256}" != "dev-mode" ]; then

        if [ "${TFLINT_SHA256}" != "automatic" ]; then
            echo "${TFLINT_SHA256} *${TFLINT_FILENAME}" > tflint_checksums.txt
            sha256sum --ignore-missing -c tflint_checksums.txt
        else
            curl -sSL -o tflint_checksums.txt https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt

            set +e
            curl -sSL -o checksums.txt.keyless.sig https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.keyless.sig
            set -e

            # Check that checksums.txt.keyless.sig exists and is not empty
            if [ -s checksums.txt.keyless.sig ]; then
                # Validate checksums with cosign
                curl -sSL -o checksums.txt.pem https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.pem
                ensure_cosign
                cosign verify-blob \
                    --certificate=/tmp/tf-downloads/checksums.txt.pem \
                    --signature=/tmp/tf-downloads/checksums.txt.keyless.sig \
                    --certificate-identity-regexp="^https://github.com/terraform-linters/tflint"  \
                    --certificate-oidc-issuer=https://token.actions.githubusercontent.com \
                    /tmp/tf-downloads/tflint_checksums.txt
                # Ensure that checksums.txt has $TFLINT_FILENAME
                grep ${TFLINT_FILENAME} /tmp/tf-downloads/tflint_checksums.txt
                # Validate downloaded file
                sha256sum --ignore-missing -c tflint_checksums.txt
            else
                # Fallback to older, GPG-based verification (pre-0.47.0 of tflint)
                curl -sSL -o tflint_checksums.txt.sig https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/checksums.txt.sig
                curl -sSL -o tflint_key "${TFLINT_GPG_KEY_URI}"
                gpg -q --import tflint_key
                gpg --verify tflint_checksums.txt.sig tflint_checksums.txt
            fi
        fi
    fi

    unzip /tmp/tf-downloads/${TFLINT_FILENAME}
    mv -f tflint /usr/local/bin/
fi
if [ "${TERRAGRUNT_VERSION}" != "none" ]; then
    echo "Downloading Terragrunt..."
    terragrunt_filename="terragrunt_linux_${architecture}"
    curl -sSL -o /tmp/tf-downloads/${terragrunt_filename} https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/${terragrunt_filename}
    if [ "${TERRAGRUNT_SHA256}" != "dev-mode" ]; then
        if [ "${TERRAGRUNT_SHA256}" = "automatic" ]; then
            curl -sSL -o terragrunt_SHA256SUMS https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/SHA256SUMS
        else
            echo "${TERRAGRUNT_SHA256} *${terragrunt_filename}" > terragrunt_SHA256SUMS
        fi
        sha256sum --ignore-missing -c terragrunt_SHA256SUMS
    fi
    chmod a+x /tmp/tf-downloads/${terragrunt_filename}
    mv -f /tmp/tf-downloads/${terragrunt_filename} /usr/local/bin/terragrunt
fi

if [ "${INSTALL_SENTINEL}" = "true" ]; then
    SENTINEL_VERSION="latest"
    sentinel_releases_url='https://releases.hashicorp.com/sentinel'
    find_sentinel_version_from_url SENTINEL_VERSION ${sentinel_releases_url}
    sentinel_filename="sentinel_${SENTINEL_VERSION}_linux_${architecture}.zip"
    echo "(*) Downloading Sentinel... ${sentinel_filename}"
    curl -sSL -o /tmp/tf-downloads/${sentinel_filename} ${sentinel_releases_url}/${SENTINEL_VERSION}/${sentinel_filename}
    if [ "${SENTINEL_SHA256}" != "dev-mode" ]; then
        if [ "${SENTINEL_SHA256}" = "automatic" ]; then
            receive_gpg_keys TERRAFORM_GPG_KEY
            curl -sSL -o sentinel_checksums.txt ${sentinel_releases_url}/${SENTINEL_VERSION}/sentinel_${SENTINEL_VERSION}_SHA256SUMS
            curl -sSL -o sentinel_checksums.txt.sig ${sentinel_releases_url}/${SENTINEL_VERSION}/sentinel_${SENTINEL_VERSION}_SHA256SUMS.${TERRAFORM_GPG_KEY}.sig
            gpg --verify sentinel_checksums.txt.sig sentinel_checksums.txt
            # Verify the SHASUM matches the archive
            shasum -a 256 --ignore-missing -c sentinel_checksums.txt
        else
            echo "${SENTINEL_SHA256} *${SENTINEL_FILENAME}" >sentinel_checksums.txt
        fi
        sha256sum --ignore-missing -c sentinel_checksums.txt
    fi
    unzip /tmp/tf-downloads/${sentinel_filename}
    chmod a+x /tmp/tf-downloads/sentinel
    mv -f /tmp/tf-downloads/sentinel /usr/local/bin/sentinel
fi

if [ "${INSTALL_TFSEC}" = "true" ]; then
    TFSEC_VERSION="latest"
    find_version_from_git_tags TFSEC_VERSION 'https://github.com/aquasecurity/tfsec'
    tfsec_filename="tfsec_${TFSEC_VERSION}_linux_${architecture}.tar.gz"
    echo "(*) Downloading TFSec... ${tfsec_filename}"
    curl -sSL -o /tmp/tf-downloads/${tfsec_filename} https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/${tfsec_filename}
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
    mv -f /tmp/tf-downloads/tfsec/tfsec /usr/local/bin/tfsec
fi

if [ "${INSTALL_TERRAFORM_DOCS}" = "true" ]; then
    TERRAFORM_DOCS_VERSION="latest"
    find_version_from_git_tags TERRAFORM_DOCS_VERSION 'https://github.com/terraform-docs/terraform-docs'
    tfdocs_filename="terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${architecture}.tar.gz"
    echo "(*) Downloading Terraform docs... ${tfdocs_filename}"
    curl -sSL -o /tmp/tf-downloads/${tfdocs_filename} https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/${tfdocs_filename}
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
    chmod a+x /tmp/tf-downloads/tfdocs/terraform-docs
    mv -f /tmp/tf-downloads/tfdocs/terraform-docs /usr/local/bin/terraform-docs
fi

rm -rf /tmp/tf-downloads ${GNUPGHOME}

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
