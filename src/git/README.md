
# Git (from source) (git)

Install an up-to-date version of Git, built from source as needed. Useful for when you want the latest and greatest features. Auto-detects latest stable version and installs needed dependencies.

## Example Usage

```json
"features": {
        "ghcr.io/devcontainers/features/git:1": {
            "version": "latest"
        }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Select or enter a Git version. | string | os-provided |
| ppa | Install from PPA if available | boolean | true |

---

_Note: This file was auto-generated from the [devcontainer-feature.json](./devcontainer-feature.json)._
