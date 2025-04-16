#!/usr/bin/env bash

set -e

# Clean up
rm -rf /var/lib/apt/lists/*

INSTALL_CUDNN=${INSTALLCUDNN}
INSTALL_CUDNNDEV=${INSTALLCUDNNDEV}
INSTALL_NVTX=${INSTALLNVTX}
INSTALL_TOOLKIT=${INSTALLTOOLKIT}
CUDA_VERSION=${CUDAVERSION}
CUDNN_VERSION=${CUDNNVERSION}

. /etc/os-release 

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

if [ $VERSION_CODENAME = "bookworm" ] || [ $VERSION_CODENAME = "jammy" ] && [ $CUDA_VERSION \< 11.7 ]; then  
    echo "(!) Unsupported distribution version '${VERSION_CODENAME}' for CUDA < 11.7"
    exit 1
fi  

export DEBIAN_FRONTEND=noninteractive

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
toolkit_pkg="cuda-toolkit-${CUDA_VERSION/./-}"
if ! apt-cache show "$cuda_pkg"; then
    echo "The requested version of CUDA is not available: CUDA $CUDA_VERSION"
    exit 1
fi

echo "Installing CUDA libraries..."
apt-get install -yq "$cuda_pkg"
apt-get update -yq --fix-missing

# auto find recent cudnn version
major_cuda_version=$(echo "${CUDA_VERSION}" | cut -d '.' -f 1)
if [ "$CUDNN_VERSION" = "automatic" ]; then
    if [[ "$CUDA_VERSION" < "12.3" ]]; then
        CUDNN_VERSION=$(apt-cache policy libcudnn8 | grep "$CUDA_VERSION" | grep -Eo '^[^-1+]*' | sort -V | tail -n1 | xargs)
    else
        CUDNN_VERSION=$(apt-cache policy libcudnn9-cuda-$major_cuda_version | grep "Candidate" | awk '{print $2}' | grep -Eo '^[^-+]*')
    fi
fi
major_cudnn_version=$(echo "${CUDNN_VERSION}" | cut -d '.' -f 1)

if [ "$INSTALL_CUDNN" = "true" ]; then
    # Ensure that the requested version of cuDNN is available AND compatible
    #if major cudnn version is 9, then we need to install libcudnn9-cuda-<major_cuda_version>_<CUDNN_VERSION>-1 package
    #else we need to install libcudnn8_<CUDNN_VERSION>-1+cuda<CUDA_VERSION>" package
    if [[ $major_cudnn_version -ge "9" ]]
    then
        cudnn_pkg_version="libcudnn9-cuda-${major_cuda_version}=${CUDNN_VERSION}-1"
    else
        cudnn_pkg_version="libcudnn8=${CUDNN_VERSION}-1+cuda${CUDA_VERSION}"
    fi

    if ! apt-cache show "$cudnn_pkg_version"; then
        echo "The requested version of cuDNN is not available: cuDNN $CUDNN_VERSION for CUDA $CUDA_VERSION"
        exit 1
    fi

    echo "Installing cuDNN libraries..."
    apt-get install -yq "$cudnn_pkg_version"
fi

if [ "$INSTALL_CUDNNDEV" = "true" ]; then
    # Ensure that the requested version of cuDNN development package is available AND compatible
    #if major cudnn version is 9, then we need to install libcudnn9-dev-cuda-<major_cuda_version>_<CUDNN_VERSION>-1 package
    #else we need to install libcudnn8-dev_<CUDNN_VERSION>-1+cuda<CUDA_VERSION>" package
    if [[ $major_cudnn_version -ge "9" ]]
    then
        cudnn_dev_pkg_version="libcudnn9-dev-cuda-${major_cuda_version}=${CUDNN_VERSION}-1"
    else
        cudnn_dev_pkg_version="libcudnn8-dev=${CUDNN_VERSION}-1+cuda${CUDA_VERSION}"
    fi
    if ! apt-cache show "$cudnn_dev_pkg_version"; then
        echo "The requested version of cuDNN development package is not available: cuDNN $CUDNN_VERSION for CUDA $CUDA_VERSION"
        exit 1
    fi

    echo "Installing cuDNN dev libraries..."
    apt-get install -yq "$cudnn_dev_pkg_version"
fi

if [ "$INSTALL_NVTX" = "true" ]; then
    echo "Installing NVTX..."
    apt-get install -yq "$nvtx_pkg"
fi

if [ "$INSTALL_TOOLKIT" = "true" ]; then
    echo "Installing CUDA Toolkit..."
    apt-get install -yq "$toolkit_pkg"
fi

# Clean up
rm -rf /var/lib/apt/lists/*

echo "Done!"
