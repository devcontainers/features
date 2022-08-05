
# Docker (Docker-in-Docker) (docker-in-docker)

Create child containers *inside* a container, independent from the host's docker instance. Installs Docker extension in the container along with needed CLIs.

## Example Usage

```json
"features": {
        "devcontainers/features/docker-in-docker@latest": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Docker/Moby Engine version. (Availability can vary by OS version.) | string | latest |
| moby | Install OSS Moby build instead of Docker CE | boolean | true |
| docker_dash_compose_version | Default version of Docker Compose (v1 or v2) | string | v1 |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
