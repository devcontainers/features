#!/usr/bin/env bash

set -e

install_cuda="true"
install_cudnn=${INSTALL_CUDNN}

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Download NVIDIA's keyring package
ubuntu_version="$(lsb_release -sr | sed 's/\.//g')"
keyring_repo="https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$ubuntu_version/x86_64"
keyring_package="cuda-keyring_1.0-1_all.deb"
keyring_package_url="$keyring_repo/$keyring_package"
keyring_package_path="$(mktemp -d)"
keyring_package_file="$keyring_package_path/$keyring_package"
wget -O "$keyring_package_file" "$keyring_package_url"

# Install NVIDIA's keyring package
apt-get install -yq "$keyring_package_file"
apt-get update -yq

if [ "$install_cuda" = "true" ]; then
    echo "Installing CUDA libraries..."
    apt-get install -yq cuda-libraries-11-7
fi

if [ "$install_cudnn" = "true" ]; then
    echo "Installing cuDNN libraries..."
    apt-get install -yq libcudnn8
fi

echo "Done!"
