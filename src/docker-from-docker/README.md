
# Docker (Moby) support, reuse host Docker Engine (Docker-from-Docker) (docker-from-docker)



## Example Usage

```json
"features": [
    "docker-from-docker": {
        "id": "devcontainers/features/#{featureId}@latest",
        "options": {
            "version": "latest"
        }
    }
]
```

## Options

| Options Id | Description | Type | Default Value ||-----|-----|-----|-----|
| version | Select or enter a Docker/Moby CLI version. (Availability can vary by OS version.) | string | latest |
| moby | Install OSS Moby build instead of Docker CE | boolean | true |
| docker_dash_compose_version | Compose version to use for docker-compose (v1 or v2) | string | v1 |

---

_Note: This is an auto-generated file. Please do not directly edit._
