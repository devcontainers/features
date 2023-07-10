## Compatibility

This Feature adds shared libraries for NVIDIA CUDA and is only useful for devcontainers that run on a host machine with an NVIDIA GPU. Within your devcontainer, use the `nvidia-smi` command to ensure that your GPU is available for CUDA.

> Note: GPUs are automatically enabled for GPU machine types by the [supporting tools](https://containers.dev/supporting). Hence, there is no need to pass it through the `runArgs` to the `devcontainer.json` as it will fail dev container creations for non-GPU machine types.

If the `nvidia-smi` command is not available within your devcontainer, you may need to complete the following steps:

### Install the NVIDIA Container Toolkit

Follow [NVIDIA's instructions to install the NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/overview.html) on your host machine. The NVIDIA Container Toolkit is available on a variety of Linux distributions. Make sure you have installed the NVIDIA driver for your Linux distribution before installing the NVIDIA Container Toolkit.

## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.
