#!/usr/bin/env bash

set -e

INSTALL_CUDNN=${INSTALLCUDNN:-"false"}
INSTALL_NVTX=${INSTALLNVTX:-"false"}
CUDA_VERSION=${VERSION:-"latest"}
CUDNN_VERSION=${CUDNNVERSION:-"latest"}

# NVIDIA's package names include this information
LATEST_CUDA_VERSION="11.7"
LATEST_CUDNN_VERSION="8.5.0.96-1"
if [ "$CUDA_VERSION" = "latest" ]; then CUDA_VERSION="$LATEST_CUDA_VERSION"; fi
if [ "$CUDNN_VERSION" = "latest" ]; then CUDNN_VERSION="$LATEST_CUDNN_VERSION"; fi

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Function to run apt-get if needed
apt_get_update_if_needed() {
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

# Prints a more helpful error message when installation fails
apt_try_install() {
    apt-get install -yq "$1" || {
        local exit_code=$?
        echo "Failed to install $1"
        echo "See $NVIDIA_REPO_URL for all available packages and versions"
        return $exit_code
    }
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update_if_needed
        apt-get -y install --no-install-recommends "$@"
    fi
}

check_packages wget ca-certificates

# Add NVIDIA's package repository to apt so that we can download packages
# Always use the ubuntu2004 repo because the other repos (e.g., debian11) are missing packages
NVIDIA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64"
KEYRING_PACKAGE="cuda-keyring_1.0-1_all.deb"
KEYRING_PACKAGE_URL="$NVIDIA_REPO_URL/$KEYRING_PACKAGE"
KEYRING_PACKAGE_PATH="$(mktemp -d)"
KEYRING_PACKAGE_FILE="$KEYRING_PACKAGE_PATH/$KEYRING_PACKAGE"
wget -O "$KEYRING_PACKAGE_FILE" "$KEYRING_PACKAGE_URL"
apt-get install -yq "$KEYRING_PACKAGE_FILE"
apt-get update -yq

echo "Installing CUDA libraries..."
apt_try_install "cuda-libraries-${CUDA_VERSION/./-}"

if [ "$INSTALL_CUDNN" = "true" ]; then
    echo "Installing cuDNN libraries..."
    apt_try_install "libcudnn8=${CUDNN_VERSION}+cuda${CUDA_VERSION}"
fi

if [ "$INSTALL_NVTX" = "true" ]; then
    echo "Installing NVTX..."
    apt_try_install "cuda-nvtx-${CUDA_VERSION/./-}"
fi

echo "Done!"
