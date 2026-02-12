# Docker Outside-of-Docker with Rootless Docker

This document shows how to configure the `docker-outside-of-docker` feature with rootless Docker installations.

## Standard Rootless Docker Configuration

For a typical rootless Docker setup:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker": {
      "socketPath": "/var/run/docker-rootless.sock"
    }
  },
  "mounts": [
    {
      "source": "${env:XDG_RUNTIME_DIR}/docker.sock",
      "target": "/var/run/docker-rootless.sock",
      "type": "bind"
    }
  ]
}
```

## Custom Socket Path Configuration

For rootless Docker with custom socket location:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/docker-outside-of-docker": {
      "socketPath": "/custom/docker/socket.sock"
    }
  },
  "mounts": [
    {
      "source": "/run/user/1000/docker.sock",
      "target": "/custom/docker/socket.sock",
      "type": "bind"
    }
  ]
}
```

## Detecting Your Docker Socket

To find your Docker socket location:

```bash
# Check for rootless Docker socket
ls -la ${XDG_RUNTIME_DIR}/docker.sock
# Typically: /run/user/1000/docker.sock

# Check Docker context
docker context ls
```

## Key Points

1. **socketPath option**: Configures where the feature expects the socket inside the container
2. **Mount source**: Must match your host's actual Docker socket location
3. **Mount target**: Must match the `socketPath` option value
4. **XDG_RUNTIME_DIR**: Usually `/run/user/{uid}` for rootless Docker

## Test Scenarios

The test scenarios demonstrate:
- `rootless_docker_socket`: Standard rootless configuration
- `custom_rootless_socket_path`: Custom socket path
- `xdg_runtime_dir_socket`: XDG runtime directory style
- `root_docker_socket`: Standard root Docker (for comparison)