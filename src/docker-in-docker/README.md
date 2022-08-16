
# Docker (Docker-in-Docker) (docker-in-docker)

Create child containers *inside* a container, independent from the host's docker instance. Installs Docker extension in the container along with needed CLIs.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/docker-in-docker:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Docker/Moby Engine version. (Availability can vary by OS version.) | string | latest |
| moby | Install OSS Moby build instead of Docker CE | boolean | true |
| dockerDashComposeVersion | Default version of Docker Compose (v1 or v2) | string | v1 |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/docker-in-docker/devcontainer-feature.json)._
