#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/script-library/docs/awscli.md
# Maintainer: The VS Code and Codespaces Teams

set -e

VERSION=${VERSION:-"latest"}
VERBOSE=${VERBOSE:-"true"}

AWSCLI_GPG_KEY=FB5DB77FD5C118B80511ADA8A6310ACC4672475C
AWSCLI_GPG_KEY_MATERIAL="-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF2Cr7UBEADJZHcgusOJl7ENSyumXh85z0TRV0xJorM2B/JL0kHOyigQluUG
ZMLhENaG0bYatdrKP+3H91lvK050pXwnO/R7fB/FSTouki4ciIx5OuLlnJZIxSzx
PqGl0mkxImLNbGWoi6Lto0LYxqHN2iQtzlwTVmq9733zd3XfcXrZ3+LblHAgEt5G
TfNxEKJ8soPLyWmwDH6HWCnjZ/aIQRBTIQ05uVeEoYxSh6wOai7ss/KveoSNBbYz
gbdzoqI2Y8cgH2nbfgp3DSasaLZEdCSsIsK1u05CinE7k2qZ7KgKAUIcT/cR/grk
C6VwsnDU0OUCideXcQ8WeHutqvgZH1JgKDbznoIzeQHJD238GEu+eKhRHcz8/jeG
94zkcgJOz3KbZGYMiTh277Fvj9zzvZsbMBCedV1BTg3TqgvdX4bdkhf5cH+7NtWO
lrFj6UwAsGukBTAOxC0l/dnSmZhJ7Z1KmEWilro/gOrjtOxqRQutlIqG22TaqoPG
fYVN+en3Zwbt97kcgZDwqbuykNt64oZWc4XKCa3mprEGC3IbJTBFqglXmZ7l9ywG
EEUJYOlb2XrSuPWml39beWdKM8kzr1OjnlOm6+lpTRCBfo0wa9F8YZRhHPAkwKkX
XDeOGpWRj4ohOx0d2GWkyV5xyN14p2tQOCdOODmz80yUTgRpPVQUtOEhXQARAQAB
tCFBV1MgQ0xJIFRlYW0gPGF3cy1jbGlAYW1hem9uLmNvbT6JAlQEEwEIAD4WIQT7
Xbd/1cEYuAURraimMQrMRnJHXAUCXYKvtQIbAwUJB4TOAAULCQgHAgYVCgkICwIE
FgIDAQIeAQIXgAAKCRCmMQrMRnJHXJIXEAChLUIkg80uPUkGjE3jejvQSA1aWuAM
yzy6fdpdlRUz6M6nmsUhOExjVIvibEJpzK5mhuSZ4lb0vJ2ZUPgCv4zs2nBd7BGJ
MxKiWgBReGvTdqZ0SzyYH4PYCJSE732x/Fw9hfnh1dMTXNcrQXzwOmmFNNegG0Ox
au+VnpcR5Kz3smiTrIwZbRudo1ijhCYPQ7t5CMp9kjC6bObvy1hSIg2xNbMAN/Do
ikebAl36uA6Y/Uczjj3GxZW4ZWeFirMidKbtqvUz2y0UFszobjiBSqZZHCreC34B
hw9bFNpuWC/0SrXgohdsc6vK50pDGdV5kM2qo9tMQ/izsAwTh/d/GzZv8H4lV9eO
tEis+EpR497PaxKKh9tJf0N6Q1YLRHof5xePZtOIlS3gfvsH5hXA3HJ9yIxb8T0H
QYmVr3aIUes20i6meI3fuV36VFupwfrTKaL7VXnsrK2fq5cRvyJLNzXucg0WAjPF
RrAGLzY7nP1xeg1a0aeP+pdsqjqlPJom8OCWc1+6DWbg0jsC74WoesAqgBItODMB
rsal1y/q+bPzpsnWjzHV8+1/EtZmSc8ZUGSJOPkfC7hObnfkl18h+1QtKTjZme4d
H17gsBJr+opwJw/Zio2LMjQBOqlm3K1A4zFTh7wBC7He6KPQea1p2XAMgtvATtNe
YLZATHZKTJyiqA==
=vYOk
-----END PGP PUBLIC KEY BLOCK-----"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi


# Debian / Ubuntu packages
install_debian_packages() {
    # Ensure apt is in non-interactive to avoid prompts
    export DEBIAN_FRONTEND=noninteractive

    local package_list=""
    package_list="${package_list} curl ca-certificates gpg dirmngr unzip bash-completion less"

    local missing_package_list=""
    local packages=()
    read -r -a packages <<< "${package_list}"
    for package in "${packages[@]}"; do
        if ! dpkg-query -W -f='${db:Status-Abbrev}\n' "${package}" 2>/dev/null | grep -q '^ii'; then
            missing_package_list="${missing_package_list} ${package}"
        fi
    done

    # Install the list of missing packages
    if [ -n "${missing_package_list}" ]; then
        echo "Packages to verify are installed: ${missing_package_list}"
        rm -rf /var/lib/apt/lists/*
        apt-get update -y
        apt-get -y install --no-install-recommends ${missing_package_list} 2> >( grep -v 'debconf: delaying package configuration, since apt-utils is not installed' >&2 )
    fi

    # Clean up
    apt-get -y clean
    rm -rf /var/lib/apt/lists/*
}

# RedHat / RockyLinux / CentOS / Fedora packages
install_redhat_packages() {
    local package_list=""
    local remove_epel="false"
    local install_cmd=microdnf
    if type microdnf > /dev/null 2>&1; then
       install_cmd=microdnf
    elif type tdnf > /dev/null 2>&1; then
       install_cmd=tdnf
    elif type dnf > /dev/null 2>&1; then
       install_cmd=dnf
    elif type yum > /dev/null 2>&1; then
       install_cmd=yum
    else
       echo "Unable to find 'tdnf', 'dnf', or 'yum' package manager. Exiting."
       exit 1
    fi
    
    package_list="${package_list} curl ca-certificates gpg dirmngr unzip bash-completion less"
    
    local missing_package_list=""
    local packages=()
    read -r -a packages <<< "${package_list}"
    for package in "${packages[@]}"; do
        if ! rpm -q "${package}" >/dev/null 2>&1; then
            missing_package_list="${missing_package_list} ${package}"
        fi
    done

    if [ -n "${missing_package_list}" ]; then
        echo "Packages to verify are installed: ${missing_package_list}"
        echo "Running ${install_cmd} install..."
        if [ "${install_cmd}" = "dnf" ]; then
            ${install_cmd} -y install --allowerasing ${missing_package_list}
        else
            ${install_cmd} -y install ${missing_package_list}
        fi
    fi


}

# Alpine Linux packages
install_alpine_packages() {
    apk update
    local package_list=""

    package_list="${package_list} curl ca-certificates gnupg unzip bash-completion less"

    local missing_package_list=""
    local packages=()
    read -r -a packages <<< "${package_list}"
    for package in "${packages[@]}"; do
        if ! apk info -e "${package}" >/dev/null 2>&1; then
            missing_package_list="${missing_package_list} ${package}"
        fi
    done
    if [ -n "${missing_package_list}" ]; then
        apk add --no-cache ${missing_package_list}
    fi
}

(
    # Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
    . /etc/os-release
    # Get an adjusted ID independent of distro variants
    if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
        ADJUSTED_ID="debian"
    elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "azurelinux" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
        ADJUSTED_ID="rhel"
        VERSION_CODENAME="${ID}${VERSION_ID}"
    elif [ "${ID}" = "alpine" ]; then
        ADJUSTED_ID="alpine"
    else
        echo "Linux distro ${ID} not supported."
        exit 1
    fi

    if [ "${ADJUSTED_ID}" = "rhel" ] && [ "${VERSION_CODENAME-}" = "centos7" ]; then
        # As of 1 July 2024, mirrorlist.centos.org no longer exists.
        # Update the repo files to reference vault.centos.org.
        sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo
        sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo
        sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo
    fi

    # Install packages for appropriate OS
    case "${ADJUSTED_ID}" in
        "debian")
            install_debian_packages
            ;;
        "rhel")
            install_redhat_packages
            ;;
        "alpine")
            install_alpine_packages
            ;;
    esac
)

verify_aws_cli_gpg_signature() {
    local filePath=$1
    local sigFilePath=$2
    local awsGpgKeyring=aws-cli-public-key.gpg

    echo "${AWSCLI_GPG_KEY_MATERIAL}" | gpg --dearmor > "./${awsGpgKeyring}"
    gpg --batch --quiet --no-default-keyring --keyring "./${awsGpgKeyring}" --verify "${sigFilePath}" "${filePath}"
    local status=$?

    rm "./${awsGpgKeyring}"

    return ${status}
}

install() {
    local scriptZipFile=awscli.zip
    local scriptSigFile=awscli.sig

    # See Linux install docs at https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    if [ "${VERSION}" != "latest" ]; then
        local versionStr=-${VERSION}
    fi
    # Detect architecture without relying on dpkg (works on Alpine and non-debian systems)
    arch=$(uname -m)
    case "${arch}" in
        x86_64|amd64) architectureStr=x86_64 ;;
        aarch64|arm64) architectureStr=aarch64 ;;
        *)
            echo "AWS CLI does not support machine architecture '${arch}'. Please use an x86-64 or ARM64 machine."
            exit 1
    esac
    local scriptUrl=https://awscli.amazonaws.com/awscli-exe-linux-${architectureStr}${versionStr}.zip
    curl "${scriptUrl}" -o "${scriptZipFile}"
    curl "${scriptUrl}.sig" -o "${scriptSigFile}"

    verify_aws_cli_gpg_signature "$scriptZipFile" "$scriptSigFile"
    if (( $? > 0 )); then
        echo "Could not verify GPG signature of AWS CLI install script. Make sure you provided a valid version."
        exit 1
    fi

    if [ "${VERBOSE}" = "false" ]; then
        unzip -q "${scriptZipFile}"
    else
        unzip "${scriptZipFile}"
    fi
    
    ./aws/install

    # AWS bash completion
    mkdir -p /etc/bash_completion.d
    cp ./scripts/vendor/aws_bash_completer /etc/bash_completion.d/aws

    # AWS zsh completion
    mkdir -p /usr/local/share/zsh/site-functions/
    cp ./scripts/vendor/aws_zsh_completer.sh /usr/local/share/zsh/site-functions/_aws
    sed -i '1s/^/#compdef aws\n/' /usr/local/share/zsh/site-functions/_aws

    rm -rf ./aws
}

echo "(*) Installing AWS CLI..."

install

echo "Done!"
