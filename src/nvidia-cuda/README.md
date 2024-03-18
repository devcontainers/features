
# NVIDIA CUDA (nvidia-cuda)

Installs shared libraries for NVIDIA CUDA.

## Example Usage

```json
"features": {
    "ghcr.io/devcontainers/features/nvidia-cuda:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installCudnn | Additionally install CUDA Deep Neural Network (cuDNN) shared library | boolean | false |
| installCudnnDev | Additionally install CUDA Deep Neural Network (cuDNN) development libraries and headers | boolean | false |
| installNvtx | Additionally install NVIDIA Tools Extension (NVTX) | boolean | false |
| installToolkit | Additionally install NVIDIA CUDA Toolkit | boolean | false |
| cudaVersion | Version of CUDA to install | string | 11.8 |
| cudnnVersion | Version of cuDNN to install | string | 8.6.0.163 |

## Compatibility

This Feature adds shared libraries for NVIDIA CUDA and is only useful for devcontainers that run on a host machine with an NVIDIA GPU. Within your devcontainer, use the `nvidia-smi` command to ensure that your GPU is available for CUDA.

If the `nvidia-smi` command is not available within your devcontainer, you may need to complete the following steps:

### Install the NVIDIA Container Toolkit

Follow [NVIDIA's instructions to install the NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/overview.html) on your host machine. The NVIDIA Container Toolkit is available on a variety of Linux distributions. Make sure you have installed the NVIDIA driver for your Linux distribution before installing the NVIDIA Container Toolkit.

### Enable GPU passthrough

Enable GPU passthrough to your devcontainer by using `hostRequirements`. Here's an example of a devcontainer with this property:

```json
{
  "hostRequirements": {
    "gpu": "optional"
  }
}
```

> Note: Setting `gpu` property's value to `true` will work with GPU machine types, but fail with CPUs. Hence, setting it to `optional` works in both cases. See [schema](https://containers.dev/implementors/json_schema/#base-schema) for more configuration details.



## OS Support

This Feature should work on recent versions of Debian/Ubuntu-based distributions with the `apt` package manager installed.

`bash` is required to execute the `install.sh` script.


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/nvidia-cuda/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
