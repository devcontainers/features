#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

INSTALL_CUDNN=${INSTALLCUDNN}
INSTALL_NVTX=${INSTALLNVTX}
CUDA_VERSION=${CUDAVERSION}
CUDNN_VERSION=${CUDNNVERSION}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

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

# Ensure that the requested version of CUDA is available
cuda_pkg="cuda-libraries-${CUDA_VERSION/./-}"
nvtx_pkg="cuda-nvtx-${CUDA_VERSION/./-}"
if ! apt-cache show "$cuda_pkg"; then
    echo "The requested version of CUDA is not available: CUDA $CUDA_VERSION"
    exit 1
fi

echo "Installing CUDA libraries..."
apt-get install -yq "$cuda_pkg"

if [ "$INSTALL_CUDNN" = "true" ]; then
    # Ensure that the requested version of cuDNN is available AND compatible
    cudnn_pkg_version="libcudnn8=${CUDNN_VERSION}-1+cuda${CUDA_VERSION}"
    if ! apt-cache show "$cudnn_pkg_version"; then
        echo "The requested version of cuDNN is not available: cuDNN $CUDNN_VERSION for CUDA $CUDA_VERSION"
        exit 1
    fi

    echo "Installing cuDNN libraries..."
    apt-get install -yq "$cudnn_pkg_version"
fi

if [ "$INSTALL_NVTX" = "true" ]; then
    echo "Installing NVTX..."
    apt-get install -yq "$nvtx_pkg"
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
