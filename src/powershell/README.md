
# PowerShell (powershell)

Installs PowerShell along with needed dependencies. Useful for base Dockerfiles that often are missing required install dependencies like gpg.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/powershell:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a version of PowerShell. | string | latest |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/devcontainers/features/blob/main/src/powershell/devcontainer-feature.json)._
