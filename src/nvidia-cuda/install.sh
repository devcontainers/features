#!/usr/bin/env bash

set -e

INSTALL_CUDNN=${INSTALLCUDNN}
INSTALL_NVTX=${INSTALLNVTX}
CUDA_VERSION=${CUDAVERSION}
CUDNN_VERSION=${CUDNNVERSION}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Prints a more helpful error message when installation fails
apt_try_install() {
    apt-get install -yq "$1" || {
        local exit_code=$?
        echo "Failed to install $1"
        echo "See $NVIDIA_REPO_URL for available packages and versions"
        return $exit_code
    }
}

# Install dependencies
apt-get update -yq
apt-get install -yq wget ca-certificates

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
    apt_try_install "libcudnn8=${CUDNN_VERSION}-1+cuda${CUDA_VERSION}"
fi

if [ "$INSTALL_NVTX" = "true" ]; then
    echo "Installing NVTX..."
    apt_try_install "cuda-nvtx-${CUDA_VERSION/./-}"
fi

echo "Done!"
