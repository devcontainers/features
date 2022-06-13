
# Docker (Moby) support (Docker-in-Docker) (docker-in-docker)



## Example Usage

```json
"features: [
    "#{featureName}": {
        "id": "devcontainers/features/docker-in-docker@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value |
| version | Select or enter a Docker/Moby Engine version. (Availability can vary by OS version.) | string | latest |
| moby | Install OSS Moby build instead of Docker CE | boolean | true |
| docker_dash_compose_version | Default version of Docker Compose (v1 or v2) | string | v1 |

---

_Note: This is an auto-generated file. Please do not directly edit._
