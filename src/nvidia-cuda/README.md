
# NVIDIA CUDA (nvidia-cuda)

Installs shared libraries for NVIDIA CUDA.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/nvidia-cuda:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installCudnn | Additionally install CUDA Deep Neural Network (cuDNN) shared library | boolean | - |
| installNvtx | Additionally install NVIDIA Tools Extension (NVTX) | boolean | - |
| cudaVersion | Version of CUDA to install | string | 11.7 |
| cudnnVersion | Version of cuDNN to install | string | 8.5.0.96 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/nvidia-cuda/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
