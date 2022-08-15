#!/usr/bin/env bash

set -e

install_cudnn=${INSTALL_CUDNN}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

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

check_packages wget ca-certificates

source /etc/os-release
keyring_repo="$ID$(echo $VERSION_ID | sed 's/\.//g')/$(uname -m)"
keyring_repo_url="https://developer.download.nvidia.com/compute/cuda/repos/$keyring_repo"

keyring_package="cuda-keyring_1.0-1_all.deb"
keyring_package_url="$keyring_repo_url/$keyring_package"
keyring_package_path="$(mktemp -d)"
keyring_package_file="$keyring_package_path/$keyring_package"

# Download and install NVIDIA's keyring package
wget -O "$keyring_package_file" "$keyring_package_url"
apt-get install -yq "$keyring_package_file"
apt-get update -yq

echo "Installing CUDA libraries..."
apt-get install -yq cuda-libraries-11-7

if [ "$install_cudnn" = "true" ]; then
    echo "Installing cuDNN libraries..."
    apt-get install -yq libcudnn8
fi

echo "Done!"
