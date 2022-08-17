#!/usr/bin/env bash

set -e

install_cudnn=${INSTALLCUDNN:-"false"}
install_nvtx=${INSTALLNVTX:-"false"}
cuda_version=${VERSION:-"latest"}
cudnn_version=${CUDNNVERSION:-"latest"}

# NVIDIA's package names include this information
latest_cuda_version="11.7"
latest_cudnn_version="8.5.0.96-1"

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

# Add NVIDIA's package repository to apt so that we can download packages
# Always use the ubuntu2004 repo because the other repos (e.g., debian11) are missing packages
nvidia_repo_url="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64"
keyring_package="cuda-keyring_1.0-1_all.deb"
keyring_package_url="$nvidia_repo_url/$keyring_package"
keyring_package_path="$(mktemp -d)"
keyring_package_file="$keyring_package_path/$keyring_package"
wget -O "$keyring_package_file" "$keyring_package_url"
apt-get install -yq "$keyring_package_file"
apt-get update -yq

if [ "$cuda_version" = "latest" ]; then cuda_version="$latest_cuda_version"; fi
if [ "$cudnn_version" = "latest" ]; then cudnn_version="$latest_cudnn_version"; fi

echo "Installing CUDA libraries..."
apt-get install -yq cuda-libraries-${cuda_version/./-}

if [ "$install_cudnn" = "true" ]; then
    echo "Installing cuDNN libraries..."
    apt-get install -yq libcudnn8=${cudnn_version}+cuda${cuda_version}
fi

if [ "$install_nvtx" = "true" ]; then
    echo "Installing NVTX..."
    apt-get install -yq cuda-nvtx-${cuda_version/./-}
fi

echo "Done!"
