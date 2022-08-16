
# Docker (Docker-from-Docker) (docker-from-docker)



## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/docker-from-docker:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Docker/Moby CLI version. (Availability can vary by OS version.) | string | latest |
| moby | Install OSS Moby build instead of Docker CE | boolean | true |
| dockerDashComposeVersion | Compose version to use for docker-compose (v1 or v2) | string | v1 |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/docker-from-docker/devcontainer-feature.json)._
